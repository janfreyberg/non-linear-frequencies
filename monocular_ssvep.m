function monocular_ssvep

clear all
global pxsize frameWidth ycen xcen fixWidth scr l_key u_key d_key r_key esc_key stimRect fixLines fixPoint;

try
%% Get basic info, set filename.
clear all;
rng('shuffle');
% subject info and screen info

% ID = input('Participant ID? ', 's');
% diagnosis = input('Diagnosis? ');
scr_diagonal = 24;
scr_distance = 60;

% tstamp = clock;
% if ~isdir( fullfile(pwd, 'Results', mfilename, num2str(diagnosis)) )
%     mkdir( fullfile(pwd, 'Results', mfilename, num2str(diagnosis)) );
% end
% savefile = fullfile(pwd, 'Results', mfilename, num2str(diagnosis), [sprintf('crowding-%02d-%02d-%02d-%02d%02d-', tstamp(1), tstamp(2), tstamp(3), tstamp(4), tstamp(5)), ID, '.mat']);

%% Experiment Variables.
scr_background = 127.5;
scr_no = 0;
scr_dimensions = Screen('Rect', scr_no);
xcen = scr_dimensions(3)/2;
ycen = scr_dimensions(4)/2;

% Frame Duration
frame_dur = 1/144;

% Frequencies
freq1 = 36;
freq2 = 28.8;
nframe{1} = 144/freq1;
nframe{2} = 144/freq2;

% Trialtime in seconds
trialdur = 8;

% Stimulus
% percentage of maximum contrast
contr = 0.6;
% stimsize in degree
stimsize = 12;
% cycles per degree
cycpdegree = 2;

%% Set up Keyboard, Screen, Sound
% Keyboard
KbName('UnifyKeyNames');
u_key = KbName('UpArrow');
d_key = KbName('DownArrow');
l_key = KbName('LeftArrow');
r_key = KbName('RightArrow');
esc_key = KbName('Escape');
ent_key = KbName('Return'); ent_key = ent_key(1);
keyList = zeros(1, 256);
keyList([u_key, d_key, esc_key, ent_key]) = 1;
KbQueueCreate([], keyList); clear keyList

% I/O driver
config_io
address = hex2dec('D010');

% Sound
InitializePsychSound;
pa = PsychPortAudio('Open', [], [], [], [], [], 256);
bp400 = PsychPortAudio('CreateBuffer', pa, [MakeBeep(400, 0.2); MakeBeep(400, 0.2)]);
PsychPortAudio('FillBuffer', pa, bp400);

% Open Window
scr = Screen('OpenWindow', scr_no, scr_background);
HideCursor;
Screen('BlendFunction', scr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
% Screen('TextFont', scr, 'Segoe UI Light');
Screen('TextSize', scr, 20);

%% Prepare stimuli
% Stimsize
pxsize = visual_angle2pixel(stimsize, scr_diagonal, scr_distance, scr_no);

% Make Stimuli
grating1 = make_grating(pxsize, cycpdegree*stimsize, contr, 0);
grating{1} = Screen('MakeTexture', scr, grating1);
grating2 = make_grating(pxsize, cycpdegree*stimsize, -contr, 0);
grating{2} = Screen('MakeTexture', scr, grating2);

% Vergence Cues
fixWidth = round(pxsize/40);
if fixWidth > 10
    fixWidth = 10;
end
fixLength = round(pxsize/15);
fixLength = fixLength + mod(fixLength, 2);
frameWidth = round(pxsize/30);
if frameWidth > 10
    frameWidth = 10;
end
fixLines = [-fixLength, +fixLength, 0, 0; 0, 0, -fixLength, +fixLength];


% Stimposition etc
offset = 0;
stimRect{1} = [xcen-offset-pxsize/2, ycen-pxsize/2, xcen-offset+pxsize/2, ycen+pxsize/2];
frameRect{1} = stimRect{1} + [-frameWidth, -frameWidth, frameWidth, frameWidth];
fixPoint{1} = [xcen-offset, ycen];
angle{1} = 45;
angle{2} = -45;

%% Stimuli blocks

iBlock = 0;
for iFreq = 1:2
    for iTilt = 1:2
        for iRepetition = 1:5
            iBlock = iBlock + 1;
            seqFreq(iBlock) = iFreq; %#ok<AGROW>
            seqTilt(iBlock) = iTilt; %#ok<AGROW>
        end
    end
end
order = randperm(iBlock);
seqFreq = seqFreq(order);
seqTilt = seqTilt(order);

for stimBlock = 1:iBlock
%% Preparation
DrawFormattedText(scr, ['Trial ' num2str(stimBlock) '\nReady?'], 'center', ycen-pxsize/3, 0);
Screen('FrameRect', scr, 0, frameRect{1}, frameWidth);
Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{1});
Screen('Flip', scr);
WaitSecs(0.2);
KbWait;
WaitSecs(1);


% Reset all variables
timestamps = zeros(1, trialdur*144);
pressSecs = zeros([trialdur*144, 1]);
pressList = zeros([trialdur*144, 3]);

%% Stim Presentation

Priority(1); % using priority only for the actual trialblock
outp(address, seqFreq(stimBlock)*10 + seqTilt(stimBlock));
disp(seqFreq(stimBlock)*10 + seqTilt(stimBlock));
timestamps(1) = GetSecs;
for i = 2:trialdur*144
    
    Screen('DrawTexture', scr, grating{mod(floor(i/nframe{seqFreq(stimBlock)}), 2) + 1}, [], stimRect{1}, angle{seqTilt(stimBlock)});
    Screen('FrameRect', scr, 0, frameRect{1}, frameWidth);
    Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{1});
    timestamps(i) = Screen('Flip', scr); %, timestamps(i-1)+frame_dur, 1);
%     [~, pressSecs(i), firstPress] = KbCheck;
%     pressList(i, 1:3) = firstPress(1, [l_key, u_key, r_key]);
%     if sum(pressList(i, 1:3) ~= pressList(i-1, 1:3))
%         outp(address, binaryVectorToDecimal(pressList(i, 1:3)));
%     end

end
outp(address, 0);
Priority(0);

%% Store Data & Break
% screen refresh analysis
propDropped = mean((timestamps(2:end)-timestamps(1:end-1))>0.007);
frameDropCl = (propDropped > 0.01) * [255 0 0];

KbQueueStart;
for lapsedTime = 0:10
DrawFormattedText(scr, ['Break for ' num2str(10-lapsedTime)], 'center', ycen-pxsize/3, 0);
DrawFormattedText(scr, ['Frames dropped: ' num2str(propDropped*100) '%'], 0, 0, frameDropCl);
Screen('FrameRect', scr, 0, frameRect{1}, frameWidth);
Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{1});
Screen('Flip', scr);
[~, pressed] = KbQueueCheck;
if pressed(esc_key)
    error('Interrupted in the break');
end
WaitSecs(1);
end
KbQueueStop;

end

error('End');

catch err
%% Catch
    KbQueueFlush;
    KbQueueStop;
    sca;
%     PsychPortAudio('Close');
%     savefile = [savefile(1:(size(savefile, 2)-4)), '-ERROR.mat'];
%     save(savefile);
%     if strcmp(input('Do you want to keep the data? y / n ', 's'), 'n')
%         delete(savefile);
%         disp('Data not saved.');
%     end
    Priority(0);
    save('temp_monocular_ssvep.mat');
    rethrow(err);
end
end