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

entity conv_8to16 is
	port(
		-- System clock
		clk_in      : in    std_logic;
		reset_in    : in    std_logic;
		
		-- 8-bit data coming in
		data8_in    : in    std_logic_vector(7 downto 0);
		valid8_in   : in    std_logic;
		ready8_out  : out   std_logic;

		-- 16-bit data going out
		data16_out  : out   std_logic_vector(15 downto 0);
		valid16_out : out   std_logic;
		ready16_in  : in    std_logic
	);
end entity;

architecture rtl of conv_8to16 is
	type StateType is (
		S_WAIT_MSB,
		S_WAIT_LSB
	);
	signal state      : StateType := S_WAIT_MSB;
	signal state_next : StateType;
	signal msb        : std_logic_vector(7 downto 0) := (others => '0');
	signal msb_next   : std_logic_vector(7 downto 0);
begin
	-- Infer registers
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				state <= S_WAIT_MSB;
				msb <= (others => '0');
			else
				state <= state_next;
				msb <= msb_next;
			end if;
		end if;
	end process;

	-- Next state logic
	--process(state, msb, data8_in, valid8_in)
	process(state, msb, data8_in, valid8_in, ready16_in)
	begin
		state_next <= state;
		msb_next <= msb;
		valid16_out <= '0';
		case state is
			-- Wait for the LSB to arrive:
			when S_WAIT_LSB =>
				ready8_out <= ready16_in;  -- ready for data from 8-bit side
				data16_out <= msb & data8_in;
				if ( valid8_in = '1' and ready16_in = '1' ) then
					valid16_out <= '1';
					state_next <= S_WAIT_MSB;
				end if;
				
			-- Wait for the MSB to arrive:
			when others =>
				ready8_out <= '1';  -- ready for data from 8-bit side
				data16_out <= (others => 'X');
				if ( valid8_in = '1' ) then
					msb_next <= data8_in;
					state_next <= S_WAIT_LSB;
				end if;
		end case;
	end process;
end architecture;
