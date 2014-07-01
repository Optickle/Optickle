function demoTrapDualGUI
% GUI example where one can change T1 for green and IR and choose
% detuning with a slider
%
clear all

%put fixed params in a struct

%Plot results in standard case
hs.fig = figure;

% Add controls
% Add sliders for green and IR detuning
slrange = 5;   % slider range in hwhm
slmin   = - slrange;
slmax   = slrange;

midXG = 0.2;
midY  = 0.05;

hs.IR.s = uicontrol('Parent',hs.fig, 'Style','slider','Min',slmin,'Max',slmax,...
                'Value',0, 'Units','normalized',...
                'Position',[.2 .05 .2 .05]);
get(hs.IR.s,'Value')
hs.IR.min = uicontrol('Parent',hs.fig,'Style','text', 'Units','normalized', ...
                'Position',[.15 .05 .05 .05], 'String',num2str(slmin), ...
                'BackgroundColor',get(hs.fig,'Color'));

hs.IR.max = uicontrol('Parent',hs.fig,'Style','text','Units', 'normalized', ...
                'Position',[.4 .05 .05 .05], 'String',num2str(slmax), ...
                'BackgroundColor',get(hs.fig,'Color'));

hs.IR.lab = uicontrol('Parent',hs.fig,'Style','text','Units','normalized',...
                'Position',[.2 .1 .2 .05],...
                'String','IR detuning [HWHM]','BackgroundColor',get(hs.fig,'Color'));

% $$$ hs.IR.val = uicontrol('Parent',hs.fig,'Style','text','Units','normalized',...
% $$$                 'Position',[.2 0 .2 .05],...
% $$$                 'String',num2str(get(hs.IR.s,'Value')),'BackgroundColor',get(hs.fig,'Color'));

hs.IR.val = uicontrol('Parent',hs.fig,'Style','edit','Units','normalized',...
                'Position',[.2 0 .2 .05],...
                'String',num2str(get(hs.IR.s,'Value')),'BackgroundColor',get(hs.fig,'Color'));


set(hs.IR.s,'Callback', @(hObject,eventdata) plotSystem(hObject, ...
                                                  hs)); 
set(hs.IR.val,'Callback', @(hObject,eventdata) plotSystem(hObject, ...
                                                  hs)); 

hCaller = 0;
plotSystem(hCaller,hs);

end

function plotSystem(hCaller, handles, gFactorA, T1IR, T1G)
% Plot m/N for system with different input mirror tranmissivities
% and detunings in units of hwhm

    
    
% Do stuff that doesn't change
f   = logspace(2, 4, 600)';
P   = 1;
opt = optTrapDual(P);


    if nargin<2
        irFactorA = 0;
    else
        switch hCaller  % Who called?
          case handles.IR.val % The edit box
            L = get(handles.IR.s,{'min','max','value'});  % Get the slider's info.
            E = str2double(get(hCaller,'string'));  % Numerical edit string.
            if E >= L{1} && E <= L{2}
                set(handles.IR.s,'value',E)  % E falls within range of slider.
            else
                set(hCaller,'string',L{3}) % User tried to set slider out of range. 
            end
          case handles.IR.s % The slider
            set(handles.IR.val,'string',get(hCaller,'value')) % Set edit to current slider.
          otherwise
            % Do nothing, or whatever.
        end
        fprintf('Hello')
        irFactorA = str2double(get(handles.IR.val,'string'));
    end

    if nargin<3
        gFactorA  = 0;
    end

    
    if nargin<4
        itm   = getOptic(opt, 'IX');
        T1Vec = itm.Thr;
        T1IR   = T1Vec(1);
    end

    if nargin<5
        itm   = getOptic(opt, 'IX');
        T1Vec = itm.Thr;
        T1G   = T1Vec(2);
    end
    
    %Update labels etc
    
    %set(handles.IR.val,'String',num2str(get(handles.IR.s,'Value')))
    

% get ir and g indices

% get some drive indexes
nEX = getDriveIndex(opt, 'EX');
nIX = getDriveIndex(opt, 'IX');

% get some probe indexes
nREFL_DC = getProbeNum(opt, 'REFL_DC');
nREFL_I  = getProbeNum(opt, 'REFL_I');
nREFL_Q  = getProbeNum(opt, 'REFL_Q');

% Grab cavity length
nCavLink = getLinkNum(opt, 'IX', 'EX');
vDist    = getLinkLengths(opt);
lCav     = vDist(nCavLink);

%Get lambda - need to be careful
par       = getOptParam(opt);
lambdaVec = par.lambda;
lambdaIR  = lambdaVec(1);
lambdaG   = lambdaVec(2);

fsr   = Optickle.c / (2 * lCav);

%Compute linewidth
hwhmVec  = 0.5 * fsr * T1Vec(1:2) / (2 * pi); %Hz
hwhmMVec = (lambdaVec' / 2) .* hwhmVec / fsr; %m

%Spring stuff

f0 = 172;
Q0 = 3200;
m  = 1e-3;

mod             = getOptic(opt, 'Mod1');
gammaMod        = imag(mod.aMod);
powerCorrection = besselj(0, gammaMod)^2;

% Initialise the pos vector
pos        = zeros(opt.Ndrive, 1);

% There is a sign inversion between Corbitt and me

% a) C = 0.5, SC = 0
detA      = irFactorA * hwhmMVec(1);
pos(nIX)  = detA;
% Linewidths in m are different for different wavelengths 
% Detuning det A metres gives irFactorA half-linewidths for ir but 
% detA/hwhmM(2) half-linewidhts for the other lambda
fDetuneA  = (detA/hwhmMVec(2)-gFactorA) * hwhmVec(2); %sign
                                                     %and
                                                     %differences
                                                     %in linewidth
optA  = optTrapDual(P, fDetuneA);

[fDC, sigDC, sigAC, mMechA, noiseAC] = tickle(optA, pos, f);
%showfDC(optA, fDC);

laserA = getOptic(optA,'Laser');
PVec   = laserA.vArf.^2;

PIR = powerCorrection * PVec(1); %fix
PG  = powerCorrection * PVec(2); %fix


%    Need to account for power lost due to modulation
KIRA = opticalSpringK(PIR, - irFactorA, T1IR, lCav, f);
KGA  = opticalSpringK(PG,  - gFactorA,  T1G,  lCav, f, lambdaG);
KA   = KIRA + KGA;
tfA  = optomechanicalTF(f0, Q0, m, KA, f);




% Extract appropriate info from mMech
% (metres with rp/ metres without rp)
rpMechA = getTF(mMechA,nEX, nEX);

%Apply normal mechanical resp
% (metres without rp/ Newton)
etm          = getOptic(opt, 'EX');
pendulumResp = squeeze(freqresp(etm.mechTF, 2 * pi * f)); 

mPerNA       = pendulumResp .* rpMechA;

mPerN = [mPerNA];
tf    = [tfA];

l = 0.1; %left
b = 0.2;  %bottom
w = 0.8;  %width
h = 0.3;  %height
g = 0.15;  %gap


figure(handles.fig)
% clear existing axes
%axes('Parent', handles.fig, 'Position', [l b+h+g w h])
subplot(2,1,1)
set(gca,'Position',[l b+h+g w h],'Units','normalized')
%cla
loglog(f, abs(mPerN))
hold all
loglog(f, abs(tf),'--')
hold off
legend('Op2ickle','Theory')


subplot(2,1,2)
set(gca,'Position',[l b w h],'Units','normalized')
%axes('Parent', handles.fig, 'Position', [l b w h])
%cla
semilogx(f, 180/pi*angle(mPerN))
hold all
semilogx(f, 180/pi*angle(tf),'--')


%h = findobj(gcf,'type','axes')


end

