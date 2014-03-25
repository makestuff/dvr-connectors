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

--	Modified from conv_8to16.vhdl by Chris McClelland
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity conv_8to24 is
	port(
		-- System clock
		clk_in      : in    std_logic;
		reset_in    : in    std_logic;

		-- 8-bit data coming in
		data8_in    : in    std_logic_vector(7 downto 0);
		valid8_in   : in    std_logic;
		ready8_out  : out   std_logic;

		-- 24-bit data going out
		data24_out  : out   std_logic_vector(23 downto 0);
		valid24_out : out   std_logic;
		ready24_in  : in    std_logic
	);
end entity;

architecture rtl of conv_8to24 is
	type StateType is (
		S_WAIT_MSB,
		S_WAIT_MID,
		S_WAIT_LSB
	);
	signal state      : StateType := S_WAIT_MSB;
	signal state_next : StateType;
	signal msb        : std_logic_vector(7 downto 0) := (others => '0');
	signal msb_next   : std_logic_vector(7 downto 0);
	signal mid        : std_logic_vector(7 downto 0) := (others => '0');
	signal mid_next   : std_logic_vector(7 downto 0);
begin
	-- Infer registers
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				state <= S_WAIT_MSB;
				msb <= (others => '0');
				mid <= (others => '0');
			else
				state <= state_next;
				msb <= msb_next;
				mid <= mid_next;
			end if;
		end if;
	end process;

	-- Next state logic
	process(state, msb, mid, data8_in, valid8_in, ready24_in)
	begin
		state_next <= state;
		msb_next <= msb;
		mid_next <= mid;
		valid24_out <= '0';
		case state is
			-- Wait for the LSB to arrive:
			when S_WAIT_LSB =>
				ready8_out <= ready24_in;  -- ready for data from 8-bit side
				data24_out <= msb & mid & data8_in;
				if ( valid8_in = '1' and ready24_in = '1' ) then
					valid24_out <= '1';
					state_next <= S_WAIT_MSB;
				end if;

			-- Wait for the mid byte to arrive:
			when S_WAIT_MID =>
				ready8_out <= '1';  -- ready for data from 8-bit side
				data24_out <= (others => 'X');
				if ( valid8_in = '1' ) then
					mid_next <= data8_in;
					state_next <= S_WAIT_LSB;
				end if;

			-- Wait for the MSB to arrive:
			when others =>
				ready8_out <= '1';  -- ready for data from 8-bit side
				data24_out <= (others => 'X');
				if ( valid8_in = '1' ) then
					msb_next <= data8_in;
					state_next <= S_WAIT_MID;
				end if;
		end case;
	end process;
end architecture;
