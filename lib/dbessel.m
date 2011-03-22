% dbdx = dbessel(n, gamma)
%
% derivative of bessel function
% dbdx = d/dx [bessel(n, gamma * (1 + x)] at x = 0

%%%%%%%%%%%%%%%%%%%
% exact equation contributed by Fran�ois Bondu

function dbdx = dbessel(n, gamma)

  dbdx = gamma .* besselj(n - 1, gamma) - n .* besselj(n, gamma);
