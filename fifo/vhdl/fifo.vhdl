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

entity fifo is
	generic(
		WIDTH           : natural := 8;  -- number of bits in each FIFO word
		DEPTH           : natural := 4   -- 2**DEPTH gives number of words in FIFO
	);
	port(
		clk_in          : in  std_logic;
		reset_in        : in  std_logic;

		depth_out       : out std_logic_vector(DEPTH downto 0);

		inputData_in    : in  std_logic_vector(WIDTH-1 downto 0);
		inputValid_in   : in  std_logic;
		inputReady_out  : out std_logic;

		outputData_out  : out std_logic_vector(WIDTH-1 downto 0);
		outputValid_out : out std_logic;
		outputReady_in  : in  std_logic
	);
end entity;
