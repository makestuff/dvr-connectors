--
-- Copyright (C) 2014 Chris McClelland
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

entity conv_32to8_tb is
end entity;

architecture behavioural of conv_32to8_tb is
	-- Clocks
	signal sysClk  : std_logic;  -- main system clock
	signal dispClk : std_logic;  -- display version of sysClk, which transitions 4ns before it

	-- 32-bit interface signals
	signal data32  : std_logic_vector(31 downto 0);
	signal valid32 : std_logic;
	signal ready32 : std_logic;

	-- 8-bit interface signals
	signal data8   : std_logic_vector(7 downto 0);
	signal valid8  : std_logic;
	signal ready8  : std_logic;
begin
	-- Instantiate the memory controller for testing
	uut: entity work.conv_32to8
		port map(
			clk_in      => sysClk,
			reset_in    => '0',
			data32_in   => data32,
			valid32_in  => valid32,
			ready32_out => ready32,
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
		data32 <= (others => 'Z');
		valid32 <= '0';
		ready8 <= '0';
		wait until rising_edge(sysClk);
		while ( not endfile(inFile) ) loop
			readline(inFile, inLine);
			while ( inLine.all'length = 0 or inLine.all(1) = '#' or inLine.all(1) = ht or inLine.all(1) = ' ' ) loop
				readline(inFile, inLine);
			end loop;
			data32 <= to_4(inLine.all(1)) & to_4(inLine.all(2)) & to_4(inLine.all(3)) & to_4(inLine.all(4)) & to_4(inLine.all(5)) & to_4(inLine.all(6)) & to_4(inLine.all(7)) & to_4(inLine.all(8));
			valid32 <= to_1(inLine.all(10));
			ready8 <=  to_1(inLine.all(12));
			wait for 10 ns;
			write(outLine, from_4(data8(7 downto 4)) & from_4(data8(3 downto 0)));
			write(outLine, ' ');
			write(outLine, valid8);
			write(outLine, ' ');
			write(outLine, ready32);
			writeline(outFile, outLine);
			wait for 10 ns;
		end loop;
		data32 <= (others => 'Z');
		valid32 <= '0';
		ready8 <= '0';
		wait;
	end process;
end architecture;
