function c = con_a_b(condition,a,b)
% general ternary operator like c?a:b
% This function checks if given value is a boolean.
% INPUT:
%   condition: Boolean, or a double value.
%	a: result in case condition is true
%	b: result in case condition is false
%
% OUTPUT:
%   c: result.

% Tested: Matlab 2014a, 2014b, 2015a, Win8
% Author: Eugen Zimmermann, Konstanz, (C) 2015 eugen.zimmermann@uni-konstanz.de
    if condition
        c = a;
    else
        c = b;
    end
end

