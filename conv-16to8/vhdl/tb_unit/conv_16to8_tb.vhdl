--
-- Copyright (C) 2012 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.hex_util.all;

entity conv_16to8_tb is
end entity;

architecture behavioural of conv_16to8_tb is
	-- Clocks
	signal sysClk  : std_logic;  -- main system clock
	signal dispClk : std_logic;  -- display version of sysClk, which transitions 4ns before it

	-- 16-bit interface signals
	signal data16  : std_logic_vector(15 downto 0);
	signal valid16 : std_logic;
	signal ready16 : std_logic;

	-- 8-bit interface signals
	signal data8   : std_logic_vector(7 downto 0);
	signal valid8  : std_logic;
	signal ready8  : std_logic;
begin
	-- Instantiate the memory controller for testing
	uut: entity work.conv_16to8
		port map(
			clk_in      => sysClk,
			reset_in    => '0',
			data16_in   => data16,
			valid16_in  => valid16,
			ready16_out => ready16,
			data8_out   => data8,
			valid8_out  => valid8,
			ready8_in   => ready8
		);

	-- Drive the clocks. In simulation, sysClk lags 4ns behind dispClk, to give a visual hold time
	-- for signals in GTKWave.
	process
	begin
		sysClk <= '0';
		dispClk <= '0';
		wait for 16 ns;
		loop
			dispClk <= not(dispClk);  -- first dispClk transitions
			wait for 4 ns;
			sysClk <= not(sysClk);  -- then sysClk transitions, 4ns later
			wait for 6 ns;
		end loop;
	end process;

	-- Drive the unit under test. Read stimulus from stimulus.sim and write results to results.sim
	process
		variable inLine  : line;
		variable outLine : line;
		file inFile      : text open read_mode is "stimulus.sim";
		file outFile     : text open write_mode is "results.sim";
	begin
		data16 <= (others => 'Z');
		valid16 <= '0';
		ready8 <= '0';
		wait until rising_edge(sysClk);
		while ( not endfile(inFile) ) loop
			readline(inFile, inLine);
			while ( inLine.all'length = 0 or inLine.all(1) = '#' or inLine.all(1) = ht or inLine.all(1) = ' ' ) loop
				readline(inFile, inLine);
			end loop;
			data16 <= to_4(inLine.all(1)) & to_4(inLine.all(2)) & to_4(inLine.all(3)) & to_4(inLine.all(4));
			valid16 <= to_1(inLine.all(6));
			ready8 <=  to_1(inLine.all(8));
			wait for 10 ns;
			write(outLine, from_4(data8(7 downto 4)) & from_4(data8(3 downto 0)));
			write(outLine, ' ');
			write(outLine, valid8);
			write(outLine, ' ');
			write(outLine, ready16);
			writeline(outFile, outLine);
			wait for 10 ns;
		end loop;
		data16 <= (others => 'Z');
		valid16 <= '0';
		ready8 <= '0';
		wait;
	end process;
end architecture;
