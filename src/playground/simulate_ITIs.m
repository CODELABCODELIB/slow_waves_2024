duration = 1;
freq_increase_rate = 2;
% Time vector
t = 0:1/1000:duration; % 1000 samples/second
% Frequency as a function of time
freq = base_freq + freq_increase_rate * t;
% Phase as the integral of frequency
phase = cumsum(freq) * 2 * pi;
phase_adj = phase*1000;
% Plot the results
x =zeros(1,round(phase_adj(500)));
x(round(phase_adj(1:500))) = 1;
figure;
plot(x)