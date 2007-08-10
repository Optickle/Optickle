% dbdx = dbessel(n, gamma)
%
% derivative of bessel function
% dbdx = d/dx [bessel(n, gamma * (1 + x)] at x = 0
function dbdx = dbessel(n, gamma)
  eps = 1e-3;
  dbdx = (bessel(n, gamma * (1 + eps)) - ...
          bessel(n, gamma * (1 - eps))) / (2 * eps);
