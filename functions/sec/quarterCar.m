function [time, Z, K] = quarterCarODE(m_s, m_u, k_s0, c_s, k_t, data, motion_ratio, ax, ay)
    % Quarter car model simulation using a nested ODE function.
    wheelbase = 1.525; track = 1.4; percF = 0.6; g = 9.81; h_cg = 0.35;
    
    time_data = data.time;
    road_profile = movmean((data.signals.values/1000 - data.signals.values(1) /1000), 50);
    
    ax = interp1(linspace(time_data(1), time_data(end), length(ax)), ax, time_data, 'linear', 'extrap');
    ay = interp1(linspace(time_data(1), time_data(end), length(ay)), ay, time_data, 'linear', 'extrap');
    
    time = linspace(min(time_data), max(time_data), length(time_data));
    road_profile = interp1(time_data, road_profile, time, 'linear', 'extrap');
    z0 = [min(road_profile); 0; min(road_profile); 0];
    
    store_data = struct('wheel_rate', NaN(length(time),1), 'motion_ratio', NaN(length(time),1), 'bump_force', NaN(length(time),1), 'mass', NaN(length(time),1));
    
    [time, z] = ode45(@odefunc, time, z0);
    
    store_data.bump_force = store_data.bump_force + (m_s + m_u) * 9.81;
    K = [store_data.wheel_rate, store_data.motion_ratio, store_data.bump_force, store_data.mass];
    Z = z';
    
    function dz = odefunc(t, z)
        z_s = z(1); z_s_dot = z(2); z_u = z(3); z_u_dot = z(4);
        z_road = interp1(time, road_profile, t, 'linear', 'extrap');
        wheel_travel = z_u - z_road;
        
        % Use a new variable "current_mr" instead of overwriting "motion_ratio"
        if wheel_travel < min(motion_ratio.wheel_travel) || wheel_travel > max(motion_ratio.wheel_travel)
            current_mr = 1;
        else
            current_mr = interp1(motion_ratio.wheel_travel, motion_ratio.values, wheel_travel, 'linear', 'extrap');
        end
        
        k_s = k_s0 / current_mr^2;
        bump_force = k_s * (z_s - z_u) + c_s * (z_s_dot - z_u_dot);
        
        [~, idx] = min(abs(time - t));
        if idx >= 1 && idx <= length(time)
            store_data.wheel_rate(idx) = k_s;
            store_data.motion_ratio(idx) = current_mr;
            store_data.bump_force(idx) = bump_force;
            LTE_x = ((m_s + m_u) * ax(idx) * h_cg) / (2 * wheelbase);
            LTE_y = ((m_s + m_u) * ay(idx) * h_cg) / track * percF;
            m_s_updated = m_s + (LTE_x / g) + (LTE_y / g);
            store_data.mass(idx) = m_s_updated;
        else
            m_s_updated = m_s;
        end

        z_s_ddot = (-k_s * (z_s - z_u) - c_s * (z_s_dot - z_u_dot)) / m_s_updated;
        z_u_ddot = ( k_s * (z_s - z_u) + c_s * (z_s_dot - z_u_dot) - k_t * (z_u - z_road)) / m_u;
        dz = [z_s_dot; z_s_ddot; z_u_dot; z_u_ddot];
    end
end
