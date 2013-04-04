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

architecture rtl of fifo is
	-- Register file for storing FIFO contents
	constant DEPTH_UBOUND : natural := 2**DEPTH-1;
	constant WIDTH_UBOUND : natural := WIDTH-1;
	type RegFileType is array(DEPTH_UBOUND downto 0) of std_logic_vector(WIDTH_UBOUND downto 0);
	signal fifoData       : RegFileType := (others => (others => '0'));
	signal fifoData_next  : RegFileType;

	-- Read & write pointers, with auto-wrap incremented versions
	signal rdPtr          : unsigned(DEPTH-1 downto 0) := (others => '0');
	signal rdPtr_next     : unsigned(DEPTH-1 downto 0);
	signal rdPtr_inc      : unsigned(DEPTH-1 downto 0);
	signal wrPtr          : unsigned(DEPTH-1 downto 0) := (others => '0');
	signal wrPtr_next     : unsigned(DEPTH-1 downto 0);
	signal wrPtr_inc      : unsigned(DEPTH-1 downto 0);

	-- Full flag
	signal isFull         : std_logic := '0';
	signal isFull_next    : std_logic;

	-- Signals to drive inputReady_out & outputValid_out
	signal inputReady     : std_logic;
	signal outputValid    : std_logic;

	-- Signals that are asserted during the cycle before a write or read, respectively
	signal isWriting : std_logic;
	signal isReading : std_logic;

	-- FIFO depth stuff
	constant DEPTH_ZEROS : std_logic_vector(DEPTH-1 downto 0) := (others => '0');
	constant FULL_DEPTH : std_logic_vector(DEPTH downto 0) := '1' & DEPTH_ZEROS;
	constant EMPTY_DEPTH : std_logic_vector(DEPTH downto 0) := '0' & DEPTH_ZEROS;
begin
   -- Infer registers
   process(clk_in)
   begin
      if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				fifoData <= (others => (others => '0'));
				rdPtr <= (others => '0');
				wrPtr <= (others => '0');
				isFull <= '0';
			else
				fifoData <= fifoData_next;
				rdPtr <= rdPtr_next;
				wrPtr <= wrPtr_next;
				isFull <= isFull_next;
			end if;
		end if;
	end process;

	-- Update reg file, write pointer & isFull flag
	process(fifoData, wrPtr, wrPtr_inc, inputData_in, isWriting)
	begin
		fifoData_next <= fifoData;
		wrPtr_next <= wrPtr;
		if ( isWriting = '1' ) then
			fifoData_next(to_integer(wrPtr)) <= inputData_in;
			wrPtr_next <= wrPtr_inc;
		end if;
	end process;

	-- The FIFO only has three outputs, inputReady_out, outputData_out and outputValid_out:
	inputReady_out <= inputReady;
	inputReady <=
		'0' when isFull = '1' else
		'1';

	outputData_out <=
		fifoData(to_integer(rdPtr));

	outputValid_out <= outputValid;
	outputValid <=
		'0' when rdPtr = wrPtr and isFull = '0' else
		'1';

	-- The isReading and isWriting signals make it easier to check whether we're in a cycle that
	-- ends in a read and/or a write, respectively
	isReading <=
		'1' when outputValid = '1' and outputReady_in = '1' else
		'0';
	isWriting <=
		'1' when inputValid_in = '1' and inputReady = '1' else
		'0';

	-- Infer pointer-increment adders:
	rdPtr_inc <= rdPtr + 1;
	wrPtr_inc <= wrPtr + 1;

	-- Full when a write makes the two pointers coincide, without a read to balance it
	isFull_next <=
		'0' when isReading = '1' and rdPtr_inc /= wrPtr else
		'1' when isWriting = '1' and wrPtr_inc = rdPtr else
		isFull;

	-- Pointer increments
	rdPtr_next <=
		rdPtr_inc when isReading = '1'
		else rdPtr;
	wrPtr_next <=
		wrPtr_inc when isWriting = '1'
		else wrPtr;

	-- FIFO depth
	depth_out <=
		EMPTY_DEPTH when wrPtr = rdPtr and isFull = '0' else
		FULL_DEPTH when wrPtr = rdPtr and isFull = '1' else
		'0' & std_logic_vector(wrPtr - rdPtr) when wrPtr > rdPtr else
		std_logic_vector(('1' & wrPtr) - ('0' & rdPtr));
	
end architecture;
