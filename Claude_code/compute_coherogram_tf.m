function compute_coherogram_tf(protocolfolder, outPrefix, ftPath)
% COMPUTE_COHEROGRAM_TF
%
% Time-resolved interhemispheric C3-C4 imaginary coherence: a time x
% frequency coherogram, in the manner of Rowland, Goldberg & Jaeger
% (Neuroscience 2010), rather than a single spectrum per cell.
%
% WHY A DIFFERENT ESTIMATOR IS NEEDED
%   The band and spectrum values reported elsewhere come from mtmfft on
%   1-second epochs, which yields one spectrum per cell with no time axis.
%   Time resolution requires mtmconvol: a sliding time-frequency
%   decomposition with trials retained, followed by connectivity computed
%   across the trial ensemble separately at each time point.
%
%   Values from this script will NOT match the mtmfft values exactly. They
%   are a different estimator with different spectral smoothing, and should
%   be reported as such rather than substituted for the band results.
%
% TWO REAL CONSTRAINTS
%   1. Epochs are 1 second. Each analysis window must fit inside that, so
%      with 5-cycle windows the usable range starts near 15 Hz. Delta and
%      theta cannot be resolved in time here. FOI below is set accordingly.
%   2. Each cell has 12 trials. Coherence at each time-frequency point is
%      estimated from that ensemble, which is small; the image will be
%      noisier than one built from hundreds of trials. Interpret structure
%      that is broad and sustained, not isolated pixels.
%
% OUTPUT
%   <outPrefix>_tf_coherence.mat   grand averages per group x block x phase
%   coherogram_tf_<phase>.png/.svg time x frequency images, active, sham,
%                                  and their difference, one column per block
%
% USAGE
%   compute_coherogram_tf('D:\...\data_raw','coh')
%   compute_coherogram_tf(pf,'coh','C:\path\to\fieldtrip')

if nargin < 2 || isempty(outPrefix), outPrefix = 'coh'; end
if nargin < 3, ftPath = ''; end

%% ---- Configuration ----------------------------------------------------
FOI        = 15:1:50;      % Hz. Lower bound set by the 1-second epoch.
N_CYCLES   = 5;            % window length = N_CYCLES / f
TOI        = 0.15:0.025:0.85;   % s within the epoch, kept clear of edges
TAPER      = 'hanning';
OUT_DIR    = fullfile(pwd,'coherogram_tf');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

%% ---- FieldTrip --------------------------------------------------------
if ~isempty(ftPath)
    assert(exist(ftPath,'dir')==7,'ftPath does not exist: %s',ftPath);
    addpath(ftPath); ft_defaults;
end
if exist('ft_freqanalysis','file')~=2 && exist('ft_defaults','file')==2
    ft_defaults;
end
assert(exist('ft_freqanalysis','file')==2, 'FieldTrip not on the path.');
fprintf('FieldTrip: %s\n', which('ft_freqanalysis'));
fprintf('FOI %g-%g Hz, %d cycles, %d time points %g-%g s\n\n', ...
    FOI(1), FOI(end), N_CYCLES, numel(TOI), TOI(1), TOI(end));

roster = {
 'pro00087153_0003','CS','Stim'; 'pro00087153_0004','CS','Stim'
 'pro00087153_0005','CS','Stim'; 'pro00087153_0042','CS','Stim'
 'pro00087153_0043','CS','Stim'
 'pro00087153_0013','CS','Sham'; 'pro00087153_0015','CS','Sham'
 'pro00087153_0017','CS','Sham'; 'pro00087153_0018','CS','Sham'
 'pro00087153_0021','CS','Sham'
};   % chronic stroke only: the comparison the manuscript reports

blockNames  = {'t1','t2','t3','t4'};
blockLabels = {'BL','ES','LS','Post'};
phaseNames  = {'Hold','Prep','Move'};

% ACC.(cond){block,phase} = subjects x freq x time
ACC = struct('Stim',{cell(4,3)},'Sham',{cell(4,3)});

for s = 1:size(roster,1)
    subject = roster{s,1}; cond = roster{s,3};
    totalFile = fullfile(protocolfolder,subject,'analysis','EEGlab','EEGlab_Total.mat');
    if exist(totalFile,'file')~=2
        fprintf('  [%2d] %s : MISSING\n',s,subject); continue
    end
    fprintf('  [%2d/%2d] %s (%s)\n',s,size(roster,1),subject,cond);
    try
        S = load(totalFile,'eegevents_tfa');
        if isfield(S,'eegevents_tfa'), ev = S.eegevents_tfa;
        else, S = load(totalFile,'eegevents_ft'); ev = S.eegevents_ft; end
        clear S
    catch ME
        fprintf('        LOAD FAILED: %s\n',ME.message); continue
    end

    for b = 1:numel(blockNames)
        if ~isfield(ev.trials,blockNames{b}), continue; end
        wk = ev.trials.(blockNames{b});
        for p = 1:min(3,size(wk,1))
            peeg = wk(p,:);
            if isempty(peeg) || ~isfield(peeg,'setname') || isempty(peeg.setname)
                continue
            end
            try
                [C, fx, tx] = tfCoh(peeg, FOI, N_CYCLES, TOI, TAPER);
            catch ME
                fprintf('        %s/%s failed: %s\n', ...
                    blockLabels{b}, phaseNames{p}, ME.message);
                continue
            end
            if isempty(ACC.(cond){b,p})
                ACC.(cond){b,p} = nan(size(roster,1), numel(fx), numel(tx));
            end
            ACC.(cond){b,p}(s,:,:) = C;
            FX = fx; TX = tx;
        end
    end
    clear ev
end

save(fullfile(OUT_DIR,[outPrefix '_tf_coherence.mat']), ...
     'ACC','FX','TX','roster','blockLabels','phaseNames','FOI','TOI');
fprintf('\nSaved %s\n', fullfile(OUT_DIR,[outPrefix '_tf_coherence.mat']));

%% ---- Figures: one per movement phase ---------------------------------
for p = 1:3
    A = cell(1,4); H = cell(1,4); D = cell(1,4);
    for b = 1:4
        A{b} = squeeze(mean(ACC.Stim{b,p},1,'omitnan'));
        H{b} = squeeze(mean(ACC.Sham{b,p},1,'omitnan'));
        D{b} = A{b} - H{b};
    end
    allAH = cat(3, A{:}, H{:}); allAH = allAH(isfinite(allAH));
    cl  = [prctile_(allAH,2) prctile_(allAH,98)];
    allD = cat(3, D{:}); allD = allD(isfinite(allD));
    dl  = prctile_(abs(allD),98); if dl==0 || ~isfinite(dl); dl=1; end

    fh = figure('Position',[30 30 1320 640],'Visible','off');
    for b = 1:4
        subplot(3,4,b);      imagesc(TX,FX,A{b}); axis xy; caxis(cl);
        title(sprintf('CS active — %s',blockLabels{b}),'FontSize',9);
        if b==1, ylabel('CS active\newlineHz'); end
        colorbar; set(gca,'FontSize',8);

        subplot(3,4,4+b);    imagesc(TX,FX,H{b}); axis xy; caxis(cl);
        title(sprintf('CS sham — %s',blockLabels{b}),'FontSize',9);
        if b==1, ylabel('CS sham\newlineHz'); end
        colorbar; set(gca,'FontSize',8);

        subplot(3,4,8+b);    imagesc(TX,FX,D{b}); axis xy; caxis([-dl dl]);
        title(sprintf('active - sham — %s',blockLabels{b}),'FontSize',9);
        if b==1, ylabel('difference\newlineHz'); end
        xlabel('time within epoch (s)','FontSize',8);
        colorbar; set(gca,'FontSize',8);
    end
    sgt(sprintf(['Time-frequency C3-C4 imaginary coherence, %s phase   |   ' ...
        'chronic stroke, n=5 per condition   |   mtmconvol, %d cycles'], ...
        phaseNames{p}, N_CYCLES));
    savefig_both(fh, fullfile(OUT_DIR, ...
        sprintf('coherogram_tf_%s.png',phaseNames{p})));
end

fprintf('Figures written to %s\n', OUT_DIR);
fprintf(['\nREAD: look for structure that is sustained across time and broad\n' ...
         'in frequency. With 12 trials per cell, isolated pixels are noise.\n' ...
         'These values use a different estimator from the band results and\n' ...
         'should be reported alongside them, not in place of them.\n']);
end

% =========================================================================
function [C, fx, tx] = tfCoh(peeg, FOI, ncyc, TOI, taper)
% Time-frequency imaginary coherence between C3 and C4 across the trial
% ensemble, computed separately at each time point.

timeidx    = peeg.times >= 0;
peeg.times = peeg.times(timeidx);
peeg.data  = peeg.data(:,timeidx,:);
nTrials    = size(peeg.data,3);

ft_EEG              = [];
ft_EEG.hdr.Fs       = peeg.srate;
ft_EEG.hdr.nChans   = peeg.nbchan;
ft_EEG.hdr.labels   = {peeg.chanlocs.labels}';
ft_EEG.hdr.nSamples = peeg.pnts;
ft_EEG.hdr.nTrials  = nTrials;
ft_EEG.label        = ft_EEG.hdr.labels;
ft_EEG.time         = repmat({peeg.times/1000},1,nTrials);
for t = 1:nTrials, ft_EEG.trial{t} = double(peeg.data(:,:,t)); end
ft_EEG.fsample = peeg.srate;

cfg             = [];
cfg.output      = 'powandcsd';
cfg.method      = 'mtmconvol';
cfg.taper       = taper;
cfg.foi         = FOI;
cfg.t_ftimwin   = ncyc ./ cfg.foi;      % window length per frequency
cfg.toi         = TOI;
cfg.keeptrials  = 'yes';
cfg.channelcmb  = {'C3','C4'};
cfg.channel     = {'C3','C4'};
cfg.pad         = 'nextpow2';
freq_csd        = ft_freqanalysis(cfg, ft_EEG);

c = []; c.method='coh'; c.complex='complex';
conn = ft_connectivityanalysis(c, freq_csd);

ip = find( (strcmpi(conn.labelcmb(:,1),'C3') & strcmpi(conn.labelcmb(:,2),'C4')) | ...
           (strcmpi(conn.labelcmb(:,1),'C4') & strcmpi(conn.labelcmb(:,2),'C3')) );
if isempty(ip), error('C3-C4 pair not found'); end
ip = ip(1);

C  = squeeze(abs(imag(conn.cohspctrm(ip,:,:))));   % freq x time
fx = conn.freq(:)';
tx = conn.time(:)';
end

function v = prctile_(x,q)
x = x(isfinite(x)); x = sort(x(:));
if isempty(x), v = NaN; return; end
i = max(1, min(numel(x), round(q/100*numel(x))));
v = x(i);
end

function sgt(txt)
if exist('sgtitle','file'), sgtitle(txt,'FontSize',10);
else
    annotation('textbox',[0 0.95 1 0.05],'String',txt,'EdgeColor','none', ...
        'HorizontalAlignment','center','FontWeight','bold');
end
end

function savefig_both(fh, pngpath)
print(fh, pngpath, '-dpng','-r150');
[d,n,~] = fileparts(pngpath);
try
    print(fh, fullfile(d,[n '.svg']), '-dsvg');
catch
end
close(fh);
end
