function stimulus = retLoadStimulus(params)
% stimulus = retLoadStimulus(params)
% 
%
% Build a stimulus for retinotopy experiment by calling the appropriate
% stimulus function, depending on the experiment type
%
% April, 2010, JW: Split off from doRetinotopyScan

switch lower(params.experiment)
    case '2 rings',
        stimulus = makeRetinotopyStimulus_2rings(params);
        
    case {  '8 bars','8 bars with blanks',...
            '8 bars (sinewave)','8 bars (slow)',...
            '8 bars (lms)','8 bars (lms) with blanks',...
            '8 bars (sinewave-soft)',...
            '8 bars (sinewave-soft) with blanks',...
            '8 bars with blanks, fixed check size',...
            '8 bars with blanks thin',...
            '8 bars with blanks thick'...
            }
        stimulus = makeRetinotopyStimulus_bars(params);
        
    case '8 bars (letters)',
        stimulus = makeApertureStimulus(params);
    
    case 'experiment from file'
        stimulus = makeRetinotopyStimulusFromFile(params);
        
    otherwise,
        stimulus = makeRetinotopyStimulus(params);
end

% If we are doing ECoG, MEG, EEG, and we have not created an experiment
% from a file, then add photodiode flash to every other frame of stimulus.
% This can be used later for syncing stimulus to electrode outputs.
if ~strcmpi(params.experiment, 'experiment from file')
    stimulus = retCreateDiodeSequence(params, stimulus);
end

return
