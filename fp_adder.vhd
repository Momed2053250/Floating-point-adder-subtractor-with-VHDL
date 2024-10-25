library IEEE;       
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;             --- standard libraries 
entity fp_adder is                    --- defining the input and out put  of the adder 
  port                                           --- define the components of input nd output 
    (A      : in  std_logic_vector(31 downto 0);   --- input A 32 bit size in std logic vector     
       B      : in  std_logic_vector(31 downto 0);  --- input B 32 bit size in std logic vector 
       clk    : in  std_logic;                      
       reset  : in  std_logic;                      
       start  : in  std_logic;                    --- the start of the signal for the odule 
       done   : out std_logic;                      --- oout put indicating addition is completed 
       sum : out std_logic_vector(31 downto 0)      --- output sum of the 2 decimal numbers 
       );
end fp_adder;

architecture mixed of fp_adder is                --- the internal behaviour of our adder 
  type ST is (WAIT_STATE, ALIGN_STATE, ADDITION_STATE, NORMALIZE_STATE, OUTPUT_STATE); --- define the State types of the control unit
  signal state : ST := WAIT_STATE;   --- the current state of the control unit is set to wait_state 

  ---Internal Signals latched from the inputs
  signal A_mantissa, B_mantissa : std_logic_vector (22 downto 0);
  signal A_exp, B_exp           : std_logic_vector (7 downto 0);
  signal A_sgn, B_sgn           : std_logic;
  
  --Internal signals for Output   
  signal sum_exp: std_logic_vector (7 downto 0);
  signal sum_mantissa           : std_logic_vector (22 downto 0);
  signal sum_sgn           : std_logic;
 -- define the signal for the adder 
  signal sum_adder : std_logic_vector(22 downto 0);
  -- define a signal for the subtractor 
   signal sum_sub : std_logic_vector(22 downto 0);
   signal sum_sub2 : std_logic_vector(22 downto 0); --- 23 bits so we can use them both for the exp sub and mantissa sub 
    
signal sign_diff : signed(8 downto 0);
-- Instantiate the ADDER entity
  component adder is
    port (
      a: in std_logic_vector(22 downto 0);
      b: in std_logic_vector(22 downto 0);
      c_in : in std_logic;
      s: out std_logic_vector(22 downto 0);
      Ovrf: out std_logic
    );
  end component;
 
  -- instantiate the subtractor
  component subtractor is
  port (
    a: in std_logic_vector(22 downto 0);
    b: in std_logic_vector(22 downto 0);
    c_in: in std_logic;
    s: out std_logic_vector(22 downto 0);
    Ovrf: out std_logic
  );
  end component;
 
 --- intanstiate the signed_subtractor
   component signed_subtractor is
    port (
      a     : in  signed(8 downto 0);
      b     : in  signed(8 downto 0);
      c_in  : in  std_logic;
      s     : out signed(8 downto 0);
      Ovrf  : out std_logic
    );
  end component;
  
begin
 
  Control_Unit : process (clk, reset) is   --- define synchronous clk and reset signal 
    variable diff : signed(8 downto 0);     ---  variable defined to calculate the difference(diff) btwn exponents -- 1 more bit for the sign of the exponents
  begin                                    --- sensitive process to both clock and reset signals 
    if(reset = '1') then
      state <= WAIT_STATE;                 ---start in wait state
      done    <= '0';
    elsif rising_edge(clk) then
      case state is
        when WAIT_STATE =>
          if (start = '1') then            ---wait till start request startes high (start =1 ) then latch the signal from A and B into their corresponding places 
            A_sgn      <= A(31);
            A_exp      <= '0' & A(30 downto 23);	---One bit is added for signed subtraction
            A_mantissa <= "01" & A(22 downto 0);	---Two bits are added extra, one for leading 1 and other one for storing carry
            B_sgn      <= B(31);
            B_exp      <= '0' & B(30 downto 23);	
            B_mantissa <= "01" & B(22 downto 0);
            state    <= ALIGN_STATE;              --- responsible for aligning the exponents of A and B and preparing the mantissas for addition
          else
            state <= WAIT_STATE;    
          end if;
        when ALIGN_STATE =>                      ---Compare exponent and align it in order for mantissa to be prepared to the sum operation  (the shittiest part of the code lol)
                                                  ---If any num is greater by 2**24, we skip the addition
          if unsigned(A_exp) > unsigned(B_exp) then 
                                                 ---B needs downshifting
            diff := sign_diff;  ---- repalcing signed(A_exp) - signed(B_exp);  ---Small Alu
            if diff > 23 then
              sum_mantissa <= A_mantissa;  ---B insignificant relative to A due to the differece in exp being very small 
			  sum_exp <= A_exp;
              sum_sgn      <= A_sgn;
              state      <= OUTPUT_STATE;   --start latch A as output
            else       
			                                      ---downshift B to equilabrate B_exp to A_exp
			  sum_exp <= A_exp;      --- exponent of the sum to be same as the A to allign intially with A 
              B_mantissa(22-to_integer(diff) downto 0)  <= B_mantissa(22 downto to_integer(diff));  --- to intiger diff converts the difference variable to intiger 
              B_mantissa(22 downto 23-to_integer(diff)) <= (others => '0');
              state  <= ADDITION_STATE;
            end if;
          elsif unsigned(A_exp) < unsigned(B_exp)  then   ---A_exp < B_exp. A needs downshifting
            diff := signed(B_exp) - signed(A_exp);  --- Small Alu
            if diff > 23 then
              sum_mantissa <= B_mantissa;  ---A insignificant relative to B
              sum_sgn      <= B_sgn;
              sum_exp      <= B_exp; 
              state      <= OUTPUT_STATE;   ---start latch B as output
            else       
			                                      ---downshift A to equilabrate A_exp to B_exp
              sum_exp <= B_exp;
              A_mantissa(22-to_integer(diff) downto 0)  <= A_mantissa(22 downto to_integer(diff));
              A_mantissa(22 downto 23-to_integer(diff)) <= (others => '0');
              state                                   <= ADDITION_STATE;
            end if;
		  else				                       --- Both exponents are equal. No need to shift mantissa 
 		    sum_exp <= A_exp;
            state <= ADDITION_STATE;          
          end if;
        when ADDITION_STATE =>                    ---Mantissa addition or substraction based on sign of A and B 
          state <= NORMALIZE_STATE;
          if (A_sgn xor B_sgn) = '0' then  ---signs are the same. Just add them
            sum_mantissa <=  sum_adder;	---Big Alu   personal comment 
            sum_sgn      <= A_sgn;          ---both nums have same sign
                                            ---Else subtract smaller from larger and use sign of larger
          elsif unsigned(A_mantissa) >= unsigned(B_mantissa) then
            sum_mantissa <= sum_sub;  -- replacing std_logic_vector((unsigned(A_mantissa) - unsigned(B_mantissa)));	  ---Big Alu
            sum_sgn      <= A_sgn;
          else
            sum_mantissa <=  sum_sub2; ---std_logic_vector((unsigned(B_mantissa) - unsigned(A_mantissa)));	---Big Alu
            sum_sgn      <= B_sgn;
          end if;

        when NORMALIZE_STATE =>           ---Normalization. 
          if unsigned(sum_mantissa) = TO_UNSIGNED(0, 25) then
			                                   ---The sum is 0
            sum_mantissa <= (others => '0');  
            sum_exp        <= (others => '0');
            state      <= OUTPUT_STATE;  
          elsif(sum_mantissa(22) = '1') then       ---If sum overflowed we downshift and are done.
            sum_mantissa <= '0' & sum_mantissa(22 downto 1);     ---shift the 1 down
            sum_exp        <= std_logic_vector((unsigned(sum_exp)+ 1));
            state      <= OUTPUT_STATE;
          elsif(sum_mantissa(21) = '0') then  ---in this case we need to upshift
			                                        ---This iterates(repeats) the normalization shifts, thus can take many clocks.
			  sum_mantissa <= sum_mantissa(21 downto 0) & '0';	
			  sum_exp <= std_logic_vector((unsigned(sum_exp)-1));
			  state<= NORMALIZE_STATE;              ---keep shifting till  leading 1 appears
          else
            state <= OUTPUT_STATE;             ---leading 1 already there. Latch output
          end if;
        when OUTPUT_STATE =>
          sum(22 downto 0)  <= sum_mantissa(22 downto 0);
          sum(30 downto 23) <= sum_exp(7 downto 0);
          sum(31) <= sum_sgn;
          done              <= '1';     --- signal done
          if (start = '0') then         --- stay in the state till request ends i.e start is low
            done    <= '0';
            state <= WAIT_STATE;
          end if;
        when others =>                --- lets define any other unexpected case
			state <= WAIT_STATE;             ---Just in case.
      end case;
    end if;
  end process;
Adder1 : adder 
	port map ( 
	
      a => A_mantissa,
      b => B_mantissa,
      c_in => '0', 
      s => sum_adder
    );
    
Sub1 : subtractor 
	port map ( 
	a => A_mantissa,
      b => B_mantissa,
      c_in => '0', 
      s => sum_sub
      );
Sub2 : subtractor 
	port map( 
	a => B_mantissa,
	b => A_mantissa,
	c_in => '0',
	s => sum_sub2
	);
Signed_subtractor1 : signed_subtractor 
   port map (
   a => signed(A_exp), 
   b => signed(B_exp),
   c_in => '0',
   s => sign_diff
   );
	
end mixed;
