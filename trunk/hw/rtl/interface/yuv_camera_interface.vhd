library IEEE;
        use IEEE.std_logic_1164.all;
        use IEEE.std_logic_unsigned.all;
		  
library work;
        use work.image_pack.all ;
		  use work.utils_pack.all ;
		  use work.conf_pack.all ;

entity yuv_camera_interface is
	port(
 		clock : in std_logic; 
 		resetn : in std_logic; 
 		pixel_data : in std_logic_vector(7 downto 0 ); 
 		y_data : out std_logic_vector(7 downto 0 ); 
 		u_data : out std_logic_vector(7 downto 0 ); 
 		v_data : out std_logic_vector(7 downto 0 ); 
 		pixel_clock_out, hsync_out, vsync_out : out std_logic; 
 		pxclk, href, vsync : in std_logic
	); 
end yuv_camera_interface;

architecture systemc of yuv_camera_interface is
	TYPE pixel_state IS (WAIT_LINE, Y1, U1, Y2, V1) ; 
	
	signal pix_state : pixel_state ; 
	signal next_state : pixel_state ; 
	signal pxclk_old, pxclk_rising_edge, pxclk_falling_edge, nclk : std_logic ;
	signal en_ylatch, en_ulatch, en_vlatch : std_logic ;
	signal hsynct, vsynct, pxclkt, pixel_clock_out_t  : std_logic ;
	
	signal pclk_set, pclk_reset, first_pixeln : std_logic ;
	signal cpt_nb_pixel : std_logic_vector(1 downto 0);

	begin

y_latch : generic_latch 
	 generic map( NBIT => 8)
    port map( clk =>pxclk,
           resetn => resetn ,
           sraz => '0' ,
           en => en_ylatch ,
           d => pixel_data , 
           q => y_data);
			  
u_latch : generic_latch 
	 generic map( NBIT => 8)
    port map( clk => pxclk,
           resetn => resetn ,
           sraz => '0' ,
           en => en_ulatch ,
           d => pixel_data , 
           q => u_data);

v_latch : generic_latch 
	 generic map( NBIT => 8)
    port map( clk => pxclk,
           resetn => resetn ,
           sraz => '0' ,
           en => en_vlatch ,
           d => pixel_data , 
           q => v_data);

	process(clock, resetn)
		 begin
			if resetn = '0' then
				hsynct <= '0' ;
				vsynct <= '0' ;
				pxclkt <= '0' ;
		 	elsif  clock'event and clock = '1'  then
				hsynct <= NOT href ; -- changing href into hsync
				vsynct <= vsync ;
				pxclkt <= pxclk ;
			end if ;
	end process ;

	
	 
pixel_counter : simple_counter
	 generic map(NBIT => 2)
    port map( clk => pxclkt, 
           resetn => resetn, 
           sraz => NOT href,
           en => '1',
			  load => '0',
			  E => "00",
           Q => cpt_nb_pixel
			  );
	

	process(clock, resetn)
	begin
		if resetn = '0' then
			first_pixeln <= '0' ;
		elsif clock'event and clock = '1' then
			if href = '0' then
				first_pixeln <= '0' ;
			elsif cpt_nb_pixel /= "00"  then
				first_pixeln <= '1' ;
			end if ;
		end if ;
	end process ;


	 with cpt_nb_pixel select
		pixel_clock_out_t <=  first_pixeln when "00" , 
									 '1' when  "10" , 
									 '0' when others ;	 
	
	 with cpt_nb_pixel select
		en_ylatch <=  (href)when  "00" ,
						  '1' when  "10" ,
						  '0' when others ;
						  
	 with cpt_nb_pixel select
		en_ulatch <=  '1' when  "01" ,
						  '0' when others ;
						  
	 with cpt_nb_pixel select
		en_vlatch <=  '1' when "11"  ,
						  '0' when others ;

	
    hsync_out <= hsynct AND (NOT pixel_clock_out_t) ;	
	 vsync_out <= vsynct AND (NOT pixel_clock_out_t);
	 pixel_clock_out <= pixel_clock_out_t ;
						  
end systemc ;