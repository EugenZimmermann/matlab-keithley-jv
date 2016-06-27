function c = con_on_off(condition)
% specific ternary operator for c?'on':'off'
% This function checks if given value is a boolean.
% INPUT:
%   condition: Boolean, or a double value.
%
% OUTPUT:
%   c: 'on' in case condition is true, otherwise 'off'.

% Tested: Matlab 2014a, 2014b, 2015a, Win8
% Author: Eugen Zimmermann, Konstanz, (C) 2015 eugen.zimmermann@uni-konstanz.de
    if condition
        c = 'on';
    else
        c = 'off';
    end
end

