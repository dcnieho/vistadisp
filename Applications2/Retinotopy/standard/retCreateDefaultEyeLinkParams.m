function params = retCreateDefaultEyeLinkParams(params)

if params.useEL
    % eyelink only does 8.3 filenames, shorten subject name based
    % on that. We'll store on expt system using full name of
    % course, this is just for the host system, filename.
    eyesub_short     = params.subject(1:min(end,8));
    params.EL.filenm = [eyesub_short '.edf'];
    
    params.EL.ip        = '';       % empty: default. if non-standard, put ip, e.g. '192.168.10.13'
    params.EL.useDummy  = false;    % if true dummy mode is used, i.e., no actual EL has to be connected
    params.EL.calScale  = .7;
    params.EL.valScale  = .5;
    params.EL.basePointPositions = [
        960,540
        960,0
        960,1080
        0,540
        1920,540
        384,216
        1536,216
        384,864
        1536,864
        ];
end
