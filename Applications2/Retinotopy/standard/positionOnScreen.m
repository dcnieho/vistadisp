function destRect = positionOnScreen(params)
params_display = params.display;

% get stim to show
img = makeRetinotopyWholeStim(params);
tex = Screen('MakeTexture',params.display.windowPtr, double(img));

srcRect = [0,0,size(img, 2), size(img, 1)];
destRect = CenterRect(srcRect, params.display.rect);

% display, listen for key press, until done
while true
    break;
end
destRect = OffsetRect(destRect,-500,500);
