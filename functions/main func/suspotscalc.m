function rollsusp = suspotscalc(file)
    data = load(file);

    % Track (mm)
    trackf = 1200;
    trackr = 1200;

    % Motion Ratios
    mr_f = 1.03;
    mr_r = 1.21;

    % Roll center Height (mm) and sprung mass (kg)
    h_cg   = 0.332E3;
    h_rc_f = 0.0523E3;
    h_rc_r = 0.0873E3;
    sprung_f = 114;
    sprung_r = 114;

    h_roll = h_cg - ( h_rc_f + ( (h_rc_r - h_rc_f) * sprung_f / (sprung_f + sprung_r) ) );
    M_roll = (sprung_f + sprung_r) * h_roll;

    % Time vectors
    time_ft = data.fl_pot_travel_distance.time;   % use front as common
    time_rr = data.rl_pot_travel_distance.time;

    if isfield(data.accY, 'time')
        time_accY = data.accY.time;
    else
        time_accY = time_ft;
    end

    % Signals
    ayG  = data.accY.signals.values ./ 9.81;

    potfl = data.fl_pot_travel_distance.signals.values;
    potfr = data.fr_pot_travel_distance.signals.values;
    potrl = data.rl_pot_travel_distance.signals.values;
    potrr = data.rr_pot_travel_distance.signals.values;

    % ---- Make everything same length as time_ft BEFORE computing totalRoll
    commonTime = time_ft;

    if length(potrl) ~= length(commonTime) || ~isequal(time_rr(:), commonTime(:))
        potrl = interp1(time_rr, potrl, commonTime, 'linear', 'extrap');
        potrr = interp1(time_rr, potrr, commonTime, 'linear', 'extrap');
    end

    if length(ayG) ~= length(commonTime) || ~isequal(time_accY(:), commonTime(:))
        ayG = interp1(time_accY, ayG, commonTime, 'linear', 'extrap');
    end

    % Roll angles (degrees)
    dFront = (((potfl - potfl(1))/100) - ((potfr - potfr(1))/100)) * mr_f;
    dRear  = (((potrl - potrl(1))/100) - ((potrr - potrr(1))/100)) * mr_r;

    frontRoll = atan(dFront / trackf) * (180/pi);
    rearRoll  = atan(dRear  / trackr) * (180/pi);

    totalRoll = atan( (dFront + dRear) / (trackf + trackr) ) * (180/pi);

    % (optional) avoid divide-by-zero when ayG ~ 0
    % ayG(abs(ayG) < 1e-6) = NaN;

    roll_gradient_front = frontRoll ./ ayG;
    roll_gradient_rear  = rearRoll  ./ ayG;
    roll_gradient_total = totalRoll ./ ayG;

    K_roll_total = M_roll ./ roll_gradient_total; %#ok<NASGU>

    % Result struct
    rollsusp.time   = commonTime;
    rollsusp.values = [frontRoll, rearRoll, ayG];

    % Plot
    figure('Name','Roll Suspension');
    x1 = subplot(2,1,1);
    plot(rollsusp.time, rollsusp.values(:,1))
    title('Front Roll'); ylabel('Degrees');

    x2 = subplot(2,1,2);
    plot(rollsusp.time, rollsusp.values(:,2))
    title('Rear Roll'); xlabel('Time (s)'); ylabel('Degrees');

    linkaxes([x1, x2], 'x');
    xlim([1410, 1510])
end
