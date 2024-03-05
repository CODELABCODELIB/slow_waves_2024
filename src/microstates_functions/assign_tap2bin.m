function [dt_dt,gridx,xi] = assign_tap2bin(dt_dt, options)
%% Assign triads of taps to belong to specific bins
%
% **Usage:**
%   - assign_tap2bin(dt_dt)
%   - assign_tap2bin(... , 'Bins', 10)
%   - assign_tap2bin(... , 'MinH', 1.5)
%   - assign_tap2bin(... , 'MaxH', 5)
%
% Input(s):
%    dt_dt = array of triads with ITI of index K and ITI of index k+1 
%
%    Optional input parameters:  
% 
%      'Bins'           Number of bins (per side) in the JID. Basically the 
%                       length of the side of the JID matrix. 
%      'MinH'           The minimum delta(t) value to consider in the JID 
%                       space expressed in log10(ms) space. Default 1.5 ~ 30 ms 
%                       10 ^ 1.5 = 31.6.
%      'MaxH'           The maximum delta(t) value to consider in the JID 
%                       space expressed in log10 space. Default 5 ~  100 s 
%                       10 ^ 5 = 100000.
%
% Output(s):
%   - dt_dt: with 2 more columns where each triad has been assigned to
%   nearest bin
%   - gridx: the linearly spaced bin edges
%   - xi: X and Y coordinates for each bin
%
% Author: R.M.D. Kock, Leiden University

arguments
    dt_dt;
    options.MIN_H = 1.5;
    options.MAX_H = 5;
    options.BINS = 50;
end
%% assign taps to bins
% create linearly spaced array between the minimum and maximum times of
% size bins
gridx = linspace(options.MIN_H, options.MAX_H, options.BINS);
% get the x and y coordinates of each bin
[x1, x2] = meshgrid(gridx, gridx);
x1 = x1(:);
x2 = x2(:);
xi = [x1 x2];
%% find nearest bin of each triad
% repeat for each triad which consists of two ITI values (at interval K and K+1)
for sel_tap=1:size(dt_dt,1)
    % first find all x coordinates that is nearest to K
    x = abs(xi(:,1)-dt_dt(sel_tap,1));
    [~,idx] = min(x);
    x_coordinate = find(xi(:,1)==xi(idx,1));
    
    % find all y coordinates that is nearest to K+1
    y = abs(xi(:,2)-dt_dt(sel_tap,2));
    [~,idx] = min(y);
    y_coordinate = find(xi(:,2)==xi(idx,2));
    
    % find the x and y coordinate of the triad and assign to the array of triads
    dt_dt(sel_tap,3:4) = xi(intersect(x_coordinate,y_coordinate),:);
end