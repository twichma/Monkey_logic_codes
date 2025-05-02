% object #1 = center target
% Object #2 = side target
% object #3 = sound
% object #4 = trial TTL (on during the entire trial

if ~ML_touchpresent
    error('This demo requires touch input. Please set it up or try the simulation mode.');
end

% Preparation of variables
showcursor(false);                          % remove the touchscreen cursor
bhv_code(15,'CenterOn',25,'CenterOff',30,'CenterCapture',40,'CenterHold',50,'TargetOn',60,'TargetOff',70,'CenterLeave',80,'TargetCapture',90,'RewardOn',100,'RewardOff');  % behavioral codes

% **** User parameters (times in ms, fixation_window size in degrees) ****

% Object 1 (center):
acquisition_time1=3000;      % maximal amount of time for the monkey to catch the center
hold_time1_min =600;         % minimal amount of time the center has to be touched before side target comes on
hold_time1_max =600;        % maximal amount of time the center has to be touched before side target comes on
release_time1 =500;         % maximal duration before the monkey has to let go of the center          
hold_radius1 = 5;             % determines the precision with which the center has to be hit          

% Object 2 (peripheral target):
acquisition_time2= 2000;     % maximal amount of time to catch the side target
hold_radius2 = 5;             % size of the side target

% Other timing parameters
reward_dur = 200;             % duration of solenoid activation   
intertrial_interval_min = 1500;   % minimal intertrial interval duration
intertrial_interval_max = 1800;  % maximal intertrial interval duration

%Additional notes (AG 09/23/2020):
% Hold_time1_min is the minimal amount of time that we require the monkey to touch the center before the program goes on with the task.  
% If the monkey just momentarily touches the center and then let go of it, it would not count 
%  The hold_time1_max = 300 means that the side target will come on after a randomized period, but no later than 300 ms after the monkey has
% started to touch the center. 
% 
% Release_time1 is the time we allow the monkey to hold the center with the side target on before the trial is aborted 
% (he is supposed to leave the center, not hold it!).  With 1000 ms, we give him 1 s to react to the side light illumination.

% Additional setup information for use with the National Instruments 
% NI-DAQ 9171 box: The NI-DAQ driver has several options.  When assigning
% the Reward or the TTL lines, one needs to choose the "cDAQ"
% driver to actually use the hardware ports provided by the NI box.  TTL
% ouputs are provided as events, similar to task events (such as target
% light on), and simply need to be added to the list of events that is
% being switched on or off.  An example of this is in Dan's fiber
% photometry task setup.

% **** End of user parameter section

%% Initial preparations

% calculate randomized parameters
intertrial_interval = intertrial_interval_min + rand*(intertrial_interval_max - intertrial_interval_min); % determines actual intertrial_interval
hold_time1 = hold_time1_min + rand*(hold_time1_max - hold_time1_min);

% making sure that the screen is blank and not being touched
toggleobject([1 2 3 4],'status','off');
[~,button] = mouse_position();
while button(1)                     % if there is a mouse (=touch screen) input, task is stuck
    [~,button] = mouse_position();
end

%% Center capture activities 
toggleobject([1 4],'status','on','eventmarker',3);     % turn center object on, Trial TTL is switched on
on_center = eyejoytrack('touchtarget',1,hold_radius1,acquisition_time1);  % waiting for the monkey to touch the target within the acquisition time
if ~on_center                          % if center not hit within the appropriate time, the trial is being terminated
    toggleobject([1 2 3 4],'status','off','eventmarker',25); % switch center off, set the appropriate eventmarker
    trialerror(1);                    % report error type 1: did not touch center
    return
end
eventmarker(30);         % center captured

%% Center hold
center_hold = eyejoytrack('releasetarget',1,hold_radius1,hold_time1); % measuring the time holding touch of the center
if ~center_hold                       % if the monkey relased the center too early ...  
    toggleobject([1 2 3 4],'status','off','eventmarker',25); % switch center off, set the appropriate eventmarker
    trialerror(2);                    % report error type 2: broke center target hold
    return 
end
eventmarker(40);                      % set eventmarker: CenterHold

%% Center leave
toggleobject(1,'status','off','eventmarker',25); % turn center target off,
toggleobject(2,'status','on','eventmarker',50); % turn peripheral target on (= GO signal)

[center_release,rt]  = eyejoytrack('releasetarget',1,hold_radius1,release_time1); % waiting for the monkey to leave the center position and to go to peripheral target
if center_release                    % if monkey has not reacted within the release_time1 window ...
    toggleobject([1 2 3 4],'status','off','eventmarker',60); % switch all targets off, set the appropriate eventmarker
    trialerror(3);                    % report error type 3: did not react to target
    return
end
eventmarker(70);                      % set eventmarker: CenterLeave

%% Target capture
on_target = eyejoytrack('touchtarget',2,hold_radius2,acquisition_time2);  % touching outside the window will abort the trial
if ~on_target                         % if monkey has not acquired the peripheral target within the time allowed ...
    toggleobject([1 2 3 4],'status','off','eventmarker',60); % switch peripheral target off, set the appropriate marker code
    trialerror(4);                    % report error type 4: did not capture target  
    return
end
eventmarker(80);                      % set eventmarker: TargetCapture
    
%% Reward administration
trialerror(0);                        % report error type 0: GoodTrial
toggleobject(3,'status','on');        % turn on sound
eventmarker(90);      % RewardOn
goodmonkey(200, 'juiceline',1, 'numreward',1, 'pausetime',200, 'eventmarker',80); % reward_dur of juice x 1; juice line 1 is pump, juice line 2 is solenoid
    
% cleanup
eventmarker(60)
toggleobject([1 2 3 4],'status','off','eventmarker',100); % turn the lights off
    
idle(intertrial_interval);           % wait ...