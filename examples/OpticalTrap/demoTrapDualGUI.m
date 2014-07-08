function demoTrapDualGUI
%
% GUI example of a dual carrier optical trap
%


%Get fixed params and pass in a struct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Freq vector for simulation
params.f = logspace(2, 4, 600)';

%Input power of IR beam
params.PIR = 1;

%Ratio of IR to G power PG = ratioP*PIR
params.ratioP = 1;

%Give index of IR and G
params.indIR    = 1;
params.indG     = 2;

%Run the  standard model to get params
opt = optTrapDual;

%Get default T1 values
itm         = getOptic(opt, 'IX');
T1          = itm.Thr;
params.T1IRDefault = T1(params.indIR);
params.T1GDefault  = T1(params.indG);

% Get drive indices
params.nEX    = getDriveIndex(opt, 'EX');
params.nIX    = getDriveIndex(opt, 'IX');
params.nDrive = opt.Ndrive;

% Get cavity length and fsr
nCavLink    = getLinkNum(opt, 'IX', 'EX');
vDist       = getLinkLengths(opt);
params.lCav = vDist(nCavLink);
params.fsr  = Optickle.c / (2 * params.lCav);

% Get lambda values
par              = getOptParam(opt);
params.lambdaVec = par.lambda;
params.lambdaIR  = params.lambdaVec(params.indIR);
params.lambdaG   = params.lambdaVec(params.indG);

%Get mechanical response of ETM
etm                 = getOptic(opt, 'EX');
params.pendulumResp = squeeze(freqresp(etm.mechTF, 2 * pi * params.f)); 

% $$$ % Frequency at which to evalute optical spring constants
% $$$ params.fSpringEval = 

%Add components and callbacks for the GUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create figures for the plots
hs.fig  = figure;
hs.fig2 = figure;


% Add sliders for green and IR detuning
slrange = 5;   % slider range in hwhm
slmin   = -slrange;
slmax   =  slrange;

% Add slider for ratio of powers
slPrange     = 10;
slPmin       = 1 / slPrange;
slPmax       = slPrange;
slPRange     = slPmax - slPmin;
slPMinorStep = 0.1;
slPMajorStep = 1;
sliderStepP  = [slPMinorStep / slPRange slPMajorStep / slPRange];

% Values used to position sliders, edit boxes etc.
textWidth  = 0.0505;
width      = 0.165;
leftIR     = textWidth;%0.1
leftIRT    = leftIR + width + textWidth; 
leftG      = leftIRT+3*textWidth;%0.55;
leftGT     = leftG  + width + textWidth;
leftP      = leftGT+3*textWidth;
midY       = 0.05;
height     = 0.05;
editBottom = 0;


% IR slider
hs.IR.s = uicontrol('Parent',hs.fig, 'Style','slider','Min',slmin,'Max',slmax,...
                'Value',0, 'Units','normalized',...
                'Position',[leftIR midY width height]);

hs.IR.min = uicontrol('Parent',hs.fig,'Style','text', 'Units','normalized', ...
                'Position',[leftIR-textWidth midY textWidth height], 'String',num2str(slmin), ...
                'BackgroundColor',get(hs.fig,'Color'));

hs.IR.max = uicontrol('Parent',hs.fig,'Style','text','Units', 'normalized', ...
                'Position',[leftIR+width midY textWidth height], 'String',num2str(slmax), ...
                'BackgroundColor',get(hs.fig,'Color'));

hs.IR.lab = uicontrol('Parent',hs.fig,'Style','text','Units','normalized',...
                'Position',[leftIR midY+height width height],...
                'String','IR detuning [HWHM]','BackgroundColor',get(hs.fig,'Color'));

hs.IR.val = uicontrol('Parent',hs.fig,'Style','edit','Units','normalized',...
                'Position',[leftIR editBottom width height],...
                'String',num2str(get(hs.IR.s,'Value')));


% G slider
hs.G.s = uicontrol('Parent',hs.fig, 'Style','slider','Min',slmin,'Max',slmax,...
                'Value',0, 'Units','normalized',...
                'Position',[leftG midY width height]);

hs.G.min = uicontrol('Parent',hs.fig,'Style','text', 'Units','normalized', ...
                'Position',[leftG-textWidth midY textWidth height], 'String',num2str(slmin), ...
                'BackgroundColor',get(hs.fig,'Color'));

hs.G.max = uicontrol('Parent',hs.fig,'Style','text','Units', 'normalized', ...
                'Position',[leftG+width midY textWidth height], 'String',num2str(slmax), ...
                'BackgroundColor',get(hs.fig,'Color'));

hs.G.lab = uicontrol('Parent',hs.fig,'Style','text','Units','normalized',...
                'Position',[leftG midY+height width height],...
                'String','G detuning [HWHM]','BackgroundColor',get(hs.fig,'Color'));

hs.G.val = uicontrol('Parent',hs.fig,'Style','edit','Units','normalized',...
                'Position',[leftG editBottom width height],...
                'String',num2str(get(hs.G.s,'Value')));

% IR trans box
hs.IR.T1Box = uicontrol('Parent',hs.fig,'Style','edit','Units','normalized',...
                'Position',[leftIRT editBottom 2*textWidth height],...
                'String',num2str(params.T1IRDefault));

hs.IR.T1Label = uicontrol('Parent',hs.fig,'Style','text', 'Units', ...
                      'normalized', 'Position',[leftIRT midY 2*textWidth ...
                    height], 'String','IR T1', 'BackgroundColor', ...
                      get(hs.fig,'Color'));


% G trans box
hs.G.T1Box = uicontrol('Parent',hs.fig,'Style','edit','Units','normalized',...
                'Position',[leftGT editBottom 2*textWidth height],...
                'String',num2str(params.T1GDefault));

hs.G.T1Label = uicontrol('Parent',hs.fig,'Style','text', 'Units', ...
                      'normalized', 'Position',[leftGT midY 2*textWidth ...
                    height], 'String','G T1', 'BackgroundColor', ...
                      get(hs.fig,'Color'));


% ratioP slider
hs.G.sP = uicontrol('Parent',hs.fig, 'Style','slider','Min',slPmin,'Max',slPmax,...
                'Value',1, 'SliderStep',sliderStepP,'Units','normalized',...
                'Position',[leftP midY width height]);

hs.G.minP = uicontrol('Parent',hs.fig,'Style','text', 'Units','normalized', ...
                'Position',[leftP-textWidth midY textWidth height], 'String',num2str(slPmin), ...
                'BackgroundColor',get(hs.fig,'Color'));

hs.G.maxP = uicontrol('Parent',hs.fig,'Style','text','Units', 'normalized', ...
                'Position',[leftP+width midY textWidth height], 'String',num2str(slPmax), ...
                'BackgroundColor',get(hs.fig,'Color'));

hs.G.labP = uicontrol('Parent',hs.fig,'Style','text','Units','normalized',...
                'Position',[leftP midY+height width height],...
                'String','PG/PIR','BackgroundColor',get(hs.fig,'Color'));

hs.G.valP = uicontrol('Parent',hs.fig,'Style','edit','Units','normalized',...
                'Position',[leftP editBottom width height],...
                'String',num2str(get(hs.G.sP,'Value')));
 
params.hs = hs;


% Callback functions
set(params.hs.IR.s,'Callback', @(hObject,eventdata) plotSystem(hObject, ...
                                                  params)); 

set(params.hs.IR.val,'Callback', @(hObject,eventdata) plotSystem(hObject, ...
                                                  params)); 

set(params.hs.IR.T1Box,'Callback', @(hObject,eventdata) plotSystem(hObject, ...
                                                  params)); 


set(params.hs.G.s,'Callback', @(hObject,eventdata) plotSystem(hObject, ...
                                                  params)); 

set(params.hs.G.val,'Callback', @(hObject,eventdata) plotSystem(hObject, ...
                                                  params)); 


set(params.hs.G.T1Box,'Callback', @(hObject,eventdata) plotSystem(hObject, ...
                                                  params)); 

set(params.hs.G.sP,'Callback', @(hObject,eventdata) plotSystem(hObject, ...
                                                  params)); 

set(params.hs.G.valP,'Callback', @(hObject,eventdata) plotSystem(hObject, ...
                                                  params)); 

% Plot the default system
%%%%%%%%%%%%%%%%%%%%%%%%%
plotSystem(params);

end



function plotSystem(varargin)
% Plot m/N for system with different input mirror tranmissivities
% and detunings in units of hwhm

% Deal with inputs
if nargin ==1
    hCaller = 'noCallingHandleOnFirstGo';
    params  = varargin{1};
elseif nargin==2
    hCaller = varargin{1};
    params  = varargin{2};
else
    error('Wrong number of args provided to plotSystem')
end
 
 
    


switch hCaller  % Which gui element called slider or edit box
    
  case params.hs.IR.val % The IR edit box
    L = get(params.hs.IR.s, {'min', 'max', 'value'}); % Get the slider's info.
    E = str2double(get(hCaller, 'string'));           % Numerical edit string.
    if E >= L{1} && E <= L{2}
        set(params.hs.IR.s,'value',E)  % E falls within range of slider.
    else
        set(hCaller,'string',L{3}) % User tried to set slider out of range. 
    end
    
  case params.hs.IR.s % The IR slider
    set(params.hs.IR.val,'string',get(hCaller,'value')) % Set edit to current slider.

  case params.hs.G.val % The G edit box
    L = get(params.hs.G.s, {'min', 'max', 'value'}); % Get the slider's info.
    E = str2double(get(hCaller, 'string'));          % Numerical edit string.
    if E >= L{1} && E <= L{2}
        set(params.hs.G.s,'value',E)  % E falls within range of slider.
    else
        set(hCaller,'string',L{3}) % User tried to set slider out of range. 
    end
    
  case params.hs.G.s % The G slider
    set(params.hs.G.val,'string',get(hCaller,'value')) % Set edit to current slider.

    
  case params.hs.G.valP % The power ratio edit box
    L = get(params.hs.G.sP, {'min', 'max', 'value'}); % Get the slider's info.
    E = str2double(get(hCaller, 'string'));          % Numerical edit string.
    if E >= L{1} && E <= L{2}
        set(params.hs.G.sP,'value',E)  % E falls within range of slider.
    else
        set(hCaller,'string',L{3}) % User tried to set slider out of range. 
    end
    
  case params.hs.G.sP % The power ratio slider
    set(params.hs.G.valP,'string',round(100*get(hCaller,'value'))/100) % Set edit to current slider.

  otherwise
    % Do nothing, or whatever.
end


% Set changeable parameters
irFactor = str2double(get(params.hs.IR.val, 'string'));
gFactor  = str2double(get(params.hs.G.val, 'string'));
T1IR     = str2double(get(params.hs.IR.T1Box, 'string'));
T1G      = str2double(get(params.hs.G.T1Box, 'string'));
T1Vec    = [T1IR T1G];
ratioP   = str2double(get(params.hs.G.valP, 'string'));

if any(not(T1Vec))%Test for zeros
    errordlg('If T1=0 the field in the cavity is not well-defined (T2=0). Better to choose more reasonable values.','Transmissivity Error');
    return
end

%Compute linewidth
hwhmVec  = 0.5 * params.fsr * T1Vec(1:2) / (2 * pi); %Hz
hwhmMVec = (params.lambdaVec' / 2) .* hwhmVec / params.fsr; %m


% Initialise the pos vector
pos      = zeros(params.nDrive, 1);

% There is a sign inversion between Corbitt and me

% Set detuning of cavity
lengthFactor    = - 1; %Need a minus sign bacuse a positive frequency
                       %detuning (blue detuned) requires that the cavity
                       %get longer which is a negative detuning in Optickle
det             = lengthFactor * irFactor * hwhmMVec(params.indIR);
pos(params.nIX) = det;

% Set detuning of green beam
fDetune  = (det/hwhmMVec(params.indG)+gFactor) * ...
    hwhmVec(params.indG);

% Get updated model
[opt, f0, Q0, m]  = optTrapDual(params.PIR, ratioP, fDetune, T1IR, T1G);

% Get mMech
[fDC, sigDC, sigAC, mMech, noiseAC] = tickle(opt, pos, params.f);


%Theoretical optical spring
laser = getOptic(opt, 'Laser');
PVec  = laser.vArf.^2;
PIR   = PVec(params.indIR);
PG    = PVec(params.indG); 

KIR = opticalSpringK(PIR,  irFactor, T1IR, params.lCav, params.f);
KG  = opticalSpringK(PG,   gFactor,  T1G,  params.lCav, params.f, params.lambdaG);
K   = KIR + KG;
tf  = optomechanicalTF(f0, Q0, m, K, params.f);

%Test for spring stability
if isempty(find([real(K) imag(K)]<=0))
    fprintf('\nStable spring!\n')
end

% Extract appropriate info from mMech
rpMech = getTF(mMech,params.nEX, params.nEX);

%Response of ETM
mPerN       = params.pendulumResp .* rpMech;



%Plot optical springs
%%%%%%%%%%%%%%%%%%%%%
figure(params.hs.fig2)
clf
hKIR = plot(real(KIR), imag(KIR),'r');
hold all
plot(real(KIR(1)), imag(KIR(1)),'o','MarkerSize',10,'MarkerEdgeColor','r')
plot(real(KIR(end)),imag(KIR(end)),'o','MarkerSize',10,'MarkerFaceColor','r','MarkerEdgeColor','r')
hKG = plot(real(KG), imag(KG),'g');
plot(real(KG(1)), imag(KG(1)),'o','MarkerSize',10,'MarkerEdgeColor','g')
plot(real(KG(end)), imag(KG(end)),'o','MarkerSize',10,'MarkerFaceColor','g','MarkerEdgeColor','g')
hK = plot(real(K), imag(K),'m');
plot(real(K(1)), imag(K(1)),'o','MarkerSize',10,'MarkerEdgeColor','m')
plot(real(K(end)), imag(K(end)),'o','MarkerSize',10,'MarkerFaceColor','m','MarkerEdgeColor','m')
title({sprintf('Optical spring constants from %5.2f (open cirlces)',params.f(1)),sprintf('to %5.2f Hz (filled circles)',params.f(end))})
title(sprintf(['Optical spring constants from %5.2f (open cirlces)\nto ' ...
'%5.2f Hz (filled circles)'],params.f(1),params.f(end)))
extent = max(abs([get(gca,'XLim') get(gca,'YLim')]));
areaColour = 'b';
hArea = area([0 extent],[extent extent],'EdgeColor',areaColour, ...
             'FaceColor',areaColour);
transparencyLevel = 0.75;
set(get(hArea,'Children'),'FaceAlpha',transparencyLevel);
uistack(hArea,'bottom')
hLeg = legend([hKIR hKG hK hArea],'IR','G', 'Total','Stable region','Location','SouthWest');
axis([-extent extent -extent extent])
axis square
xlabel('Real(K)')
ylabel('Imag(K)')


%Plot transfer function
%%%%%%%%%%%%%%%%%%%%%%%

% Parameters for laying out plot
l = 0.1;   %left
b = 0.3;   %bottom
w = 0.8;   %width
h = 0.275; %height
g = 0.05;  %gap


figure(params.hs.fig)

subplot(2,1,1)
loglog(params.f, abs(mPerN))
hold all
loglog(params.f, abs(tf),'--')
hold off
legend('Op2ickle','Theory')
set(gca,'Position',[l b+h+g w h],'Units','normalized','XTickLabel',[])
title('ETM response')
ylabel('Mag. [m/N]')

subplot(2,1,2)
set(gca,'Position',[l b w h],'Units','normalized')
semilogx(params.f, 180/pi*angle(mPerN))
hold all
semilogx(params.f, 180/pi*angle(tf),'--')
xlabel('Frequency [Hz]')
ylabel('Phase [deg.]')
set(gca,'YTick',-360:90:360)


end

