function destRect = positionOnScreen(params)

% get stim to show
img = makeRetinotopyWholeStim(params);
tex = Screen('MakeTexture',params.display.windowPtr, double(img));

srcRect = [0,0,size(img, 2), size(img, 1)];

% check if positioning info already exist for this subject
posfile = fullfile(params.homeDir,'stimulusPositioning',sprintf('%s.mat',params.subject));
if ~~exist(posfile,'file')
    a=load(posfile);
    destRect = a.destRect;
else
    destRect = CenterRect(srcRect, params.display.rect);
end

% display, listen for key press, until done
stepSz = 10;
while true
    % show 
    Screen('DrawTexture', params.display.windowPtr, tex, [], destRect);
    Screen('Flip', params.display.windowPtr);
    
    % listen to keyboard
    [~,keyCode] = KbWait([],3);
    if any(keyCode)
        keys = KbName(keyCode);
        if ~iscell(keys), keys = {keys}; end
        if any(cellfun(@(x) ~isempty(strfind(lower(x(1:min(2,end))),'up')),keys)) %#ok<STREMP>
            % up arrow key (test so round-about
            % because KbName could return both 'up'
            % and 'UpArrow', depending on platform
            % and mode)
            if destRect(2)>=stepSz
                destRect = OffsetRect(destRect,0,-stepSz);
            end
        elseif any(cellfun(@(x) ~isempty(strfind(lower(x(1:min(4,end))),'down')),keys)) %#ok<STREMP>
            % down key
            if destRect(4)<=params.display.rect(4)-stepSz
                destRect = OffsetRect(destRect,0,stepSz);
            end
        end
        if any(cellfun(@(x) ~isempty(strfind(lower(x(1:min(4,end))),'left')),keys)) %#ok<STREMP>
            if destRect(1)>=stepSz
                destRect = OffsetRect(destRect,-stepSz,0);
            end
        elseif any(cellfun(@(x) ~isempty(strfind(lower(x(1:min(5,end))),'right')),keys)) %#ok<STREMP>
            % right key
            if destRect(3)<=params.display.rect(3)-stepSz
                destRect = OffsetRect(destRect,stepSz,0);
            end
        end
        
        
        % check for done
        if any(strcmpi(keys,'escape')) || any(strcmpi(keys,'space'))
            break;
        end
    end
end

% save to file for later initialization of this display
save(posfile,'destRect');

% clear screen
Screen('Flip', params.display.windowPtr);
