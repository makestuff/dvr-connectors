--
-- Copyright (C) 2013 Joel Pérez Izquierdo
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

--	Modified from conv_16to8.vhdl by Chris McClelland
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity conv_24to8 is
	port(
		-- System clock & reset
		clk_in      : in    std_logic;
		reset_in    : in    std_logic;

		-- 24-bit data coming in
		data24_in   : in    std_logic_vector(23 downto 0);
		valid24_in  : in    std_logic;
		ready24_out : out   std_logic;

		-- 8-bit data going out
		data8_out   : out   std_logic_vector(7 downto 0);
		valid8_out  : out   std_logic;
		ready8_in   : in    std_logic
	);
end entity;

architecture rtl of conv_24to8 is
	type StateType is (
		S_WRITE_MSB,
		S_WRITE_MID,
		S_WRITE_LSB
	);
	signal state      : StateType := S_WRITE_MSB;
	signal state_next : StateType;
	signal lsb        : std_logic_vector(7 downto 0) := (others => '0');
	signal lsb_next   : std_logic_vector(7 downto 0);
	signal mid        : std_logic_vector(7 downto 0) := (others => '0');
	signal mid_next   : std_logic_vector(7 downto 0);
begin
	-- Infer registers
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				state <= S_WRITE_MSB;
				lsb <= (others => '0');
				mid <= (others => '0');
			else
				state <= state_next;
				lsb <= lsb_next;
				mid <= mid_next;
			end if;
		end if;
	end process;

	-- Next state logic
	process(state, lsb, mid, data24_in, valid24_in, ready8_in)
	begin
		state_next <= state;
		valid8_out <= '0';
		lsb_next <= lsb;
		mid_next <= mid;
		case state is
			-- Write the LSB and return to MSB:
			when S_WRITE_LSB =>
				ready24_out <= '0';  -- not ready for data from 24-bit side
				data8_out <= lsb;
				if ( ready8_in = '1' ) then
					valid8_out <= '1';
					state_next <= S_WRITE_MSB;
				end if;

			-- Write the mid byte and move on to LSB
			when S_WRITE_MID =>
				ready24_out <= '0';  -- not ready for data from 24-bit side
				data8_out <= mid;
				if ( ready8_in = '1' ) then
					valid8_out <= '1';
					state_next <= S_WRITE_LSB;
				end if;			
				
			-- When a word arrives, write the MSB and move on to mid byte:				
			when others =>
				ready24_out <= ready8_in;  -- ready for data from 24-bit side
				data8_out <= data24_in(23 downto 16);
				valid8_out <= valid24_in;
				if ( valid24_in = '1' and ready8_in = '1' ) then
					mid_next <= data24_in(15 downto 8);
					lsb_next <= data24_in(7 downto 0);
					state_next <= S_WRITE_MID;
				end if;
		end case;
	end process;
end architecture;
