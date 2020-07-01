function img = makeRetinotopyWholeStim(params)

outerRad        = params.radius;
%innerRad        = params.innerRad;
ringWidth       = params.ringWidth;

halfNumImages   = params.numImages./2;
numMotSteps     = params.temporal.motionSteps;
numSubRings     = params.numSubRings;

%%% Set check colormap indices %%%
%bk = findName(params.display.reservedColor,'background');
%minCmapVal = max([params.display.reservedColor(:).fbVal])+1;
%maxCmapVal = params.display.numColors-1;
bk = params.display.backColorIndex;

minCmapVal = min([params.display.stimRgbRange]);
maxCmapVal = max([params.display.stimRgbRange]);

if isfield(params, 'contrast')
    c = params.contrast;
    bg = (minCmapVal + maxCmapVal)/2;
    minCmapVal = round((1-c) * bg);
    maxCmapVal = round((1+c) * bg);
end

%%% Initialize image template %%%
m = round(2 * angle2pix(params.display, outerRad));
n = round(2 * angle2pix(params.display, outerRad));

% should really do something more intelligent, like outerRad-fix
[x,y]=meshgrid(linspace(-outerRad,outerRad,n),linspace(outerRad,-outerRad,m));

% here we crop the image if it is larger than the screen
% seems that you have to have a square matrix, bug either in my or
% psychtoolbox' code - so we make it square
if m>params.display.numPixels(2),
    start  = round((m-params.display.numPixels(2))/2);
    len    = params.display.numPixels(2);
    y = y(start+1:start+len, start+1:start+len);
    x = x(start+1:start+len, start+1:start+len);
    m = len;
    n = len;
end

% r = eccentricity;
r = sqrt (x.^2  + y.^2);

% loop over different orientations and make checkerboard
% first define which orientations
orientations = (0:45:360)./360*(2*pi); % degrees -> rad
orientations = orientations([1 6 3 8 5 2 7 4]);
remake_xy    = zeros(1,params.numImages)-1;
remake_xy(1:length(remake_xy)/length(orientations):length(remake_xy)) = orientations;
original_x   = x;
original_y   = y;
% step size of the bar
step_nx      = params.period./params.tr/8;
step_x       = (2*outerRad) ./ step_nx;
step_startx  = (step_nx-1)./2.*-step_x - (ringWidth./2);

imgNum=1;

if remake_xy(imgNum) >=0,
    x = original_x .* cos(remake_xy(imgNum)) - original_y .* sin(remake_xy(imgNum));
    y = original_x .* sin(remake_xy(imgNum)) + original_y .* cos(remake_xy(imgNum));
    % Calculate checkerboard.
    % Wedges alternating between -1 and 1 within stimulus window.
    % The computational contortions are to avoid sign=0 for sin zero-crossings
    wedges    = sign(round((cos((x+step_startx)*numSubRings*(2*pi/ringWidth)))./2+.5).*2-1);
    posWedges = find(wedges== 1);
    negWedges = find(wedges==-1);
    rings     = zeros(size(wedges));
    
    ii = 1;
    tmprings1 = sign(2*round((cos(y*numSubRings*(2*pi/ringWidth)+(ii-1)/numMotSteps*2*pi)+1)/2)-1);
    tmprings2 = sign(2*round((cos(y*numSubRings*(2*pi/ringWidth)-(ii-1)/numMotSteps*2*pi)+1)/2)-1);
    rings(posWedges) = tmprings1(posWedges);
    rings(negWedges) = tmprings2(negWedges);
    
    checks=minCmapVal+ceil((maxCmapVal-minCmapVal) * (wedges.*rings+1)./2);
end



% Can we do this just be removing the second | from the window
% expression? so...
window = r<outerRad;

img         = bk*ones(size(checks));
img(window) = checks(window);
img = uint8(img); %#ok<*BDSCA>
