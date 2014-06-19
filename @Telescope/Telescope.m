classdef Telescope < Optic
  % Telescope is a type of Optic used in Optickle
  %
  % Telescopes are used for changing the beam size to match
  % cavities, or to add Gouy phase for readout.  A telescope
  % is made up of N + 1 lenses with N distances between them.
  %
  % NOTE: the audio phase accumulated while propagating through
  % a telescope is NOT included.  Typically this phase is very
  % small (e.g., for a 1 meter telescope, a 300Hz audio SB should
  % gain 1e-6 radians of phase).  In special cases where the
  % audio phase is of interest, break the telescope into individual
  % lenses (with the distaces being represented by links).
  %
  % obj = Telescope(name, f)
  %   or, to add more lenses after the first append an
  %   Nx2 matrix of distance and focal length pairs
  % obj = Telescope(name, f, df)
  %
  % A telescope has 1 input and 1 output.
  % Input:  1, in
  % Output: 1, out
  %
  % ==== Members
  % Optic - base class members
  % f - focal length of first lens
  % df - distances from previous lens and lens focal length
  %      for lenses after the first
  %
  % ==== Functions, those in Optic
  %
  % % Example: a telescope at transmission port (10x reduction, then focus)
  % obj = Telescope('TRAN_TELE', 2, [2.2 0.2; 0.2 0.3]);
  
  properties
    f = 1;    % focal length of first lens
    
    % df - distances from previous lens and lens focal length
    %      for lenses after the first
    df = [];
  end

  methods
    function obj = Telescope(varargin)
      
      errstr = 'Don''t know what to do with ';	% for argument error messages
      name = '';
      switch( nargin )
        case 0					% default constructor, do nothing
        case {2 3}
          % ==== copy constructor
%          arg = varargin{1};
%           if( isa(arg, class(obj)) )
%             obj = arg;
%             return
%           end
          
          % ==== name, loss
          args = {'', 1, []};
          args(1:nargin) = varargin(1:end);
          [name, f_arg, df_arg] = deal(args{:});          
        otherwise
          % wrong number of input args
          error([errstr '%d input arguments.'], nargin);
      end
      
      % build optic (a telescope has no drives)
      obj@Optic(name, {'in'}, {'out'}, {});
      obj.f = f_arg;
      obj.df = df_arg;
    end
    function mOpt = getFieldMatrix(obj, pos, par)
      % getFieldMatrix method
      %   returns a mOpt, the field transfer matrix for this optic
      %
      % mOpt = getFieldMatrix(obj, pos, par)
      
      if isempty(obj.df)
        % send inputs to outputs
        mOpt = speye(par.Nrf, par.Nrf);
      else
        % account for RF propagation phase
        d = sum(obj.df(:, 1));
        v = exp(1i * d * 2 * pi * par.vFrf / Optickle.c);
        
        % send inputs to outputs
        mOpt = sparse(diag(v));
      end
    end
    function [mOptAC, mOpt] = getFieldMatrixAC(obj, pos, par)
      % getFieldMatrixAC method
      %   returns a mOpt, the field transfer matrix for this optic
      %   a telescope adds Gouy phase for the TEM01 and TEM10 modes
      %
      % mOpt = getFieldMatrixAC(obj, pos, par)
      
      % start with default field matrix
      mOpt = getFieldMatrix(obj, pos, par);
      
      % add Gouy phase
      if par.tfType ~= Optickle.tfPos
        % compute Gouy phase
        phi = getTelescopePhase(obj, par.vBin);
      
        % send inputs to outputs with Gouy phase
        mOpt = mOpt * exp(1i * phi(par.nBasis));
      end
      
      % expand to both audio sidebands
      mOptAC = Optic.expandFieldMatrixAF(mOpt);
    end

    function [phi, bOut] = getTelescopePhase(obj, bOut)
      % [phi, bOut] = getTelescopePhase(obj, bIn)
      %   returns the Gouy phase accumulated in this telescope by
      %   an input beam with basis bIn (1x2).  The output basis is
      %   also computed and returned as bOut.
      
      % compute Gouy phase
      qm = focus(OpHG, 1 ./ obj.f);
      
      my_df = obj.df;
      phi = [0 0];
      for n = 1:size(my_df, 1)
        % add shift to focus operator
        qm = shift(qm, my_df(n, 1));
        
        % apply the focus-shift operator to the input basis
        bOut = apply(qm, bOut);
        
        % add the resulting Gouy phase
        phi = phi + angle(bOut - my_df(n, 1)) - angle(bOut);
        
        % compute next focus operator
        qm = focus(OpHG, 1 ./ my_df(n, 2));
      end
      
      % compute final output basis
      bOut = apply(qm, bOut);
    end
    function qm = getBasisMatrix(obj)
      % get the basis change matrix for this Telescope
      
      qm = focus(OpHG, 1 ./ obj.f);
      my_df = obj.df;
      for n = 1:size(my_df, 1)
        qm = shift(qm, my_df(n, 1));
        qm = focus(qm, 1 ./ my_df(n, 2));
      end
    end
  end    % methods
end      % classdef
