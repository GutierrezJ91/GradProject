library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package my_pkg is
 function log2 (x : positive) return natural;
end my_pkg;

package body my_pkg is
    function log2 (x : positive) return natural is
          variable i : natural;
       begin
          i := 0;  
          while (2**i < x) loop
             i := i + 1;
          end loop;
          return i;
       end function;
end my_pkg;