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

entity fifo_tb is
	generic(
		WIDTH           : natural := 8;  -- number of bits in each FIFO word
		DEPTH           : natural := 2   -- 2**DEPTH gives number of words in FIFO
	);
end entity;

architecture behavioural of fifo_tb is
	-- Clocks
	signal sysClk      : std_logic;  -- main system clock
	signal dispClk     : std_logic;  -- display version of sysClk, which transitions 4ns before it

	-- Depth
	signal curDepth    : std_logic_vector(DEPTH downto 0);
	
	-- Input pipe
	signal inputData   : std_logic_vector(WIDTH-1 downto 0);
	signal inputValid  : std_logic;
	signal inputReady  : std_logic;

	-- Output pipe
	signal outputData  : std_logic_vector(WIDTH-1 downto 0);
	signal outputValid : std_logic;
	signal outputReady : std_logic;
begin
	-- Instantiate the FIFO for testing
	uut: entity work.fifo
		generic map(
			WIDTH => WIDTH,
			DEPTH => DEPTH
		)
		port map(
			clk_in         => sysClk,
			reset_in       => '0',
			depth_out      => curDepth,

			-- Input pipe
			inputData_in   => inputData,
			inputValid_in  => inputValid,
			inputReady_out => inputReady,

			-- Output pipe
			outputData_out  => outputData,
			outputValid_out => outputValid,
			outputReady_in  => outputReady
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
		inputData <= (others => 'X');
		inputValid <= '0';
		outputReady <= '0';
		wait until rising_edge(sysClk);
		while ( not endfile(inFile) ) loop
			readline(inFile, inLine);
			while ( inLine.all'length = 0 or inLine.all(1) = '#' or inLine.all(1) = ht or inLine.all(1) = ' ' ) loop
				readline(inFile, inLine);
			end loop;
			inputData <= to_4(inLine.all(1)) & to_4(inLine.all(2));
			inputValid <= to_1(inLine.all(4));
			outputReady <= to_1(inLine.all(6));
			wait for 10 ns;
			write(outLine, from_4(inputData(7 downto 4)) & from_4(inputData(3 downto 0)));
			write(outLine, ' ');
			write(outLine, inputValid);
			write(outLine, ' ');
			write(outLine, inputReady);
			write(outLine, ' ');
			if ( inputReady = '1' and inputValid = '1' ) then
				write(outLine, '*');
			else
				write(outLine, ' ');
			end if;
			write(outLine, ' ');
			write(outLine, '|');
			write(outLine, ' ');
			if ( DEPTH = 2 ) then
				write(outLine, from_4('0' & curDepth));
			elsif ( DEPTH = 3 ) then
				write(outLine, from_4(curDepth));
			end if;
			write(outLine, ' ');
			write(outLine, '|');
			write(outLine, ' ');
			write(outLine, from_4(outputData(7 downto 4)) & from_4(outputData(3 downto 0)));
			write(outLine, ' ');
			write(outLine, outputValid);
			write(outLine, ' ');
			write(outLine, outputReady);
			if ( outputReady = '1' and outputValid = '1' ) then
				write(outLine, ' ');
				write(outLine, '*');
			end if;
			writeline(outFile, outLine);
			wait for 10 ns;
		end loop;
		inputData <= (others => 'X');
		inputValid <= '0';
		outputReady <= '0';
		wait;
	end process;
end architecture;
