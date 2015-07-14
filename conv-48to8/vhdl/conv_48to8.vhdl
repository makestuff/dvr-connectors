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

entity conv_48to8 is
	port(
		-- System clock & reset
		clk_in      : in    std_logic;
		reset_in    : in    std_logic;

		-- 48-bit data coming in
		data48_in   : in    std_logic_vector(47 downto 0);
		valid48_in  : in    std_logic;
		ready48_out : out   std_logic;

		-- 8-bit data going out
		data8_out   : out   std_logic_vector(7 downto 0);
		valid8_out  : out   std_logic;
		ready8_in   : in    std_logic
	);
end entity;

architecture rtl of conv_48to8 is
	type StateType is (
		S_WRITE0,
		S_WRITE1,
		S_WRITE2,
		S_WRITE3,
		S_WRITE4,
		S_WRITE5
	);
	signal state      : StateType := S_WRITE0;
	signal state_next : StateType;
	signal wip        : std_logic_vector(39 downto 0) := (others => '0');
	signal wip_next   : std_logic_vector(39 downto 0);
begin
	-- Infer registers
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				state <= S_WRITE0;
				wip <= (others => '0');
			else
				state <= state_next;
				wip <= wip_next;
			end if;
		end if;
	end process;

	-- Next state logic
	process(state, wip, data48_in, valid48_in, ready8_in)
	begin
		state_next <= state;
		valid8_out <= '0';
		wip_next <= wip;
		case state is
			-- Write byte 1
			when S_WRITE1 =>
				ready48_out <= '0';  -- not ready for data from 48-bit side
				data8_out <= wip(39 downto 32);
				if ( ready8_in = '1' ) then
					valid8_out <= '1';
					state_next <= S_WRITE2;
				end if;
				
			-- Write byte 2
			when S_WRITE2 =>
				ready48_out <= '0';  -- not ready for data from 48-bit side
				data8_out <= wip(31 downto 24);
				if ( ready8_in = '1' ) then
					valid8_out <= '1';
					state_next <= S_WRITE3;
				end if;
				
			-- Write byte 3
			when S_WRITE3 =>
				ready48_out <= '0';  -- not ready for data from 48-bit side
				data8_out <= wip(23 downto 16);
				if ( ready8_in = '1' ) then
					valid8_out <= '1';
					state_next <= S_WRITE4;
				end if;
				
			-- Write byte 4
			when S_WRITE4 =>
				ready48_out <= '0';  -- not ready for data from 48-bit side
				data8_out <= wip(15 downto 8);
				if ( ready8_in = '1' ) then
					valid8_out <= '1';
					state_next <= S_WRITE5;
				end if;
				
			-- Write byte 5 (LSB)
			when S_WRITE5 =>
				ready48_out <= '0';  -- not ready for data from 48-bit side
				data8_out <= wip(7 downto 0);
				if ( ready8_in = '1' ) then
					valid8_out <= '1';
					state_next <= S_WRITE0;
				end if;
				
			-- When a word arrives, write byte 0 (MSB)
			when others =>
				ready48_out <= ready8_in;  -- ready for data from 48-bit side
				data8_out <= data48_in(47 downto 40);
				valid8_out <= valid48_in;
				if ( valid48_in = '1' and ready8_in = '1' ) then
					wip_next <= data48_in(39 downto 0);
					state_next <= S_WRITE1;
				end if;
		end case;
	end process;
end architecture;
