if ~ML_touchpresent, error('This demo requires touch input. Please set it up or try the simulation mode.'); end

showcursor(false);                          % remove the touchscreen cursor
bhv_code(20,'Sample',40,'Go',50,'Reward',100,'TrialEnd');  % behavioral codes

% give names to the TaskObjects defined in the conditions file:
sample = 1;
sound_sample = 2;

% ttl_t = timer('ExecutionMode','singleShot');
% ttl_t.StartDelay = 0.0005;
% ttl_t.TimerFcn = @(~, ~)toggleobject(3,'status','off');

% define time intervals (in ms):
sample_time = 3000;
%% 
delay = 3000;
max_reaction_time = 1000;
itt_basic = 2000;           % inter-trial intervals will not be any shorter than this time (in ms)
itt_rand = 3000;            % random component added to inter-trial intervals (in ms)

% fixation window (in degrees):
hold_radius = 10;

% TASK:

% proceed only when the screen is not being touched
[~,button] = mouse_position();
while button(1)                     % if there is a mouse (=touch screen) input, task is stuck
    [~,button] = mouse_position();
end

% sample epoch
toggleobject([1 4], 'eventmarker',20);     % turn on the target circle
ontarget = eyejoytrack('touchtarget',sample,hold_radius,sample_time);  % touching outside the window will abort the trial

if ontarget
    toggleobject(3,'status','on');
    %pause(0.001);
    idle(5);                        % duration of TTL pulse - this has an overhead - the actual pulse is ~1.8 ms longer than the nominal value pulse is about 2.8 ms
    toggleobject(3,'status','off');
    %start(ttl_t);
    
    toggleobject(2);                 % turn on sound
    goodmonkey(300, 'juiceline',1, 'numreward',1, 'pausetime',700, 'eventmarker',50); % 300 ms of juice x 1
    toggleobject(2);
    trialerror(0);  % good trial
else
    trialerror(3);  % bad trial    
end

%delete(ttl_t);
toggleobject([1 4],'eventmarker',100);
idle(itt_basic + rand(1)*itt_rand);  % wait ...