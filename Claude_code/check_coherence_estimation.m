function check_coherence_estimation(protocolfolder, subject, blockName, phaseIdx)
% CHECK_COHERENCE_ESTIMATION
% Diagnostic for Reviewer 2, Methods comment 11 (Welch / ensemble averaging).
%
% PURPOSE
%   EEGLAB_imaginarycoh.m computes coherence inside a loop over single trials
%   (cfg.trials = t). This script determines how many independent observations
%   (trials x tapers) enter each coherence estimate, and whether the resulting
%   quantity is a coherence estimate or a per-trial phase-difference measure.
%
%   If each estimate is built from ONE trial and ONE taper, then |coherency| is
%   identically 1 by construction and cfg.complex='absimag' reduces to
%   |sin(phase difference)|. This script tests that directly and, for
%   comparison, recomputes coherence across the trial ensemble.
%
% USAGE
%   check_coherence_estimation('D:\Roddey_tdcs_eeg\Data\data_raw','pro00087153_0003')
%   check_coherence_estimation(pf,'pro00087153_0003','t3',2)   % late stim, Prep
%
% INPUTS
%   protocolfolder - folder containing pro00087153_XXXX subject directories
%   subject        - e.g. 'pro00087153_0003'
%   blockName      - 't1'..'t4'  (default 't3' = late stimulation)
%   phaseIdx       - 1=Hold, 2=Prep, 3=Move (default 2 = Prep)
%
% REQUIRES
%   FieldTrip on the MATLAB path (ft_defaults already run).
%
% OUTPUT
%   Printed report + <subject>_coherence_diagnostic.txt written to the
%   subject's analysis/EEGlab folder. Send that .txt file back for review.

if nargin < 3 || isempty(blockName), blockName = 't3'; end
if nargin < 4 || isempty(phaseIdx),  phaseIdx  = 2;    end

phaseNames = {'Hold','Prep','Move'};

analysisfolder = fullfile(protocolfolder, subject, 'analysis', 'EEGlab');
totalFile      = fullfile(analysisfolder, 'EEGlab_Total.mat');

assert(exist(totalFile,'file')==2, 'EEGlab_Total.mat not found: %s', totalFile);

% -------------------------------------------------------------------------
% Set up logging to file as well as screen
% -------------------------------------------------------------------------
outFile = fullfile(analysisfolder, [subject '_coherence_diagnostic.txt']);
fid = fopen(outFile,'w');
log = @(varargin) logboth(fid, varargin{:});

log('========================================================\n');
log(' COHERENCE ESTIMATION DIAGNOSTIC\n');
log(' Subject : %s\n', subject);
log(' Block   : %s     Phase: %s\n', blockName, phaseNames{phaseIdx});
log(' Date    : %s\n', datestr(now));
log('========================================================\n\n');

% -------------------------------------------------------------------------
% Load the phase-split structure (as EEGLAB_imaginarycoh.m receives it)
% -------------------------------------------------------------------------
log('Loading %s ...\n', totalFile);
S = load(totalFile, 'eegevents_tfa');
if ~isfield(S,'eegevents_tfa')
    S = load(totalFile, 'eegevents_ft');
    assert(isfield(S,'eegevents_ft'), 'Neither eegevents_tfa nor eegevents_ft found.');
    ev = S.eegevents_ft;
else
    ev = S.eegevents_tfa;
end
clear S

assert(isfield(ev.trials, blockName), 'Block %s not present in eegevents.trials', blockName);
wkEEG = ev.trials.(blockName);
assert(size(wkEEG,1) >= phaseIdx, 'Phase index %d exceeds available phases (%d).', phaseIdx, size(wkEEG,1));

peeg = wkEEG(phaseIdx,:);
assert(~isempty(peeg.setname), 'Selected block/phase is empty for this subject.');

% -------------------------------------------------------------------------
% Rebuild the FieldTrip structure EXACTLY as EEGLAB_imaginarycoh.m does
% -------------------------------------------------------------------------
timeidx      = peeg.times >= 0;
peeg.times   = peeg.times(timeidx);
peeg.data    = peeg.data(:, timeidx, :);

nTrials = size(peeg.data,3);
winSec  = (numel(peeg.times)) / peeg.srate;

log('Sampling rate         : %g Hz\n', peeg.srate);
log('Analysis window       : %.4f s (%d samples, times >= 0)\n', winSec, numel(peeg.times));
log('Trials (epochs) avail : %d\n', nTrials);
log('Channels in struct    : %d\n\n', peeg.nbchan);

ft_EEG              = [];
ft_EEG.hdr.Fs       = peeg.srate;
ft_EEG.hdr.nChans   = peeg.nbchan;
ft_EEG.hdr.labels   = {peeg.chanlocs.labels}';
ft_EEG.hdr.nSamples = peeg.pnts;
ft_EEG.hdr.nTrials  = nTrials;
ft_EEG.label        = ft_EEG.hdr.labels;
ft_EEG.time         = repmat({peeg.times/1000}, 1, nTrials);
for t = 1:nTrials
    ft_EEG.trial{t} = double(peeg.data(:,:,t));
end
ft_EEG.fsample = peeg.srate;

% -------------------------------------------------------------------------
% Locate C3 and C4
% -------------------------------------------------------------------------
labels = ft_EEG.label(1:min(21,numel(ft_EEG.label)));
iC3 = findchan(labels,'C3');
iC4 = findchan(labels,'C4');
log('C3 channel index      : %s\n', num2str(iC3));
log('C4 channel index      : %s\n\n', num2str(iC4));

% =========================================================================
% PART 1 - Spectral estimation with the ORIGINAL configuration
% =========================================================================
log('--------------------------------------------------------\n');
log(' PART 1: ft_freqanalysis with the ORIGINAL cfg\n');
log('--------------------------------------------------------\n');

cfg              = [];
cfg.output       = 'powandcsd';
cfg.method       = 'mtmfft';
cfg.taper        = 'dpss';
cfg.pad          = 'maxperlen';
cfg.keeptrials   = 'yes';
cfg.tapsmofrq    = 1;
cfg.channel      = 1:21;
freq_csd         = ft_freqanalysis(cfg, ft_EEG);

log('cfg.tapsmofrq         : %g Hz\n', cfg.tapsmofrq);
log('size(powspctrm)       : [%s]   (rpt x chan x freq)\n', num2str(size(freq_csd.powspctrm)));
log('size(crsspctrm)       : [%s]   (rpt x chancmb x freq)\n', num2str(size(freq_csd.crsspctrm)));
log('freq resolution       : %.4f Hz\n', freq_csd.freq(2)-freq_csd.freq(1));

if isfield(freq_csd,'cumtapcnt')
    tapersPerTrial = unique(freq_csd.cumtapcnt(:));
    log('cumtapcnt (tapers/trl): %s\n', mat2str(tapersPerTrial'));
    K = tapersPerTrial(1);
else
    K = NaN;
    log('cumtapcnt             : FIELD ABSENT\n');
end

Kexpected = max(1, 2*winSec*cfg.tapsmofrq - 1);
log('expected K = 2*T*W-1  : %g   (T=%.3f s, W=%g Hz)\n\n', Kexpected, winSec, cfg.tapsmofrq);

% =========================================================================
% PART 2 - Per-trial coherence (what the current pipeline computes)
% =========================================================================
log('--------------------------------------------------------\n');
log(' PART 2: PER-TRIAL coherence (current implementation)\n');
log('--------------------------------------------------------\n');

magPerTrial = nan(nTrials,1);
absimagPerTrial = nan(nTrials,1);
gammaBand = [30 50];

for t = 1:nTrials
    cfgc            = [];
    cfgc.method     = 'coh';
    cfgc.complex    = 'complex';    % full complex coherency for diagnosis
    cfgc.trials     = t;
    connC           = ft_connectivityanalysis(cfgc, freq_csd);

    ipair = findpair(connC.labelcmb, 'C3', 'C4');
    if isempty(ipair)
        log('  !! C3-C4 pair not found in labelcmb\n');
        break
    end
    fidx = connC.freq >= gammaBand(1) & connC.freq <= gammaBand(2);

    cohc = connC.cohspctrm(ipair, fidx);
    magPerTrial(t)     = mean(abs(cohc));
    absimagPerTrial(t) = mean(abs(imag(cohc)));
end

log('Gamma band            : %g-%g Hz\n', gammaBand(1), gammaBand(2));
log('mean |coherency| per trial (across trials) : %.6f\n', nanmean(magPerTrial));
log('   min %.6f   max %.6f   sd %.3e\n', nanmin(magPerTrial), nanmax(magPerTrial), nanstd(magPerTrial));
log('mean |imag(coherency)| (= absimag)         : %.6f\n\n', nanmean(absimagPerTrial));

isDegenerate = abs(nanmean(magPerTrial) - 1) < 1e-6;
if isDegenerate
    log('>>> |coherency| == 1 to numerical precision.\n');
    log('>>> Each estimate has ONE observation; this is NOT a coherence\n');
    log('>>> estimate. absimag here equals |sin(phase difference)|.\n\n');
else
    log('>>> |coherency| < 1: more than one observation is entering the\n');
    log('>>> estimate. Report the taper count above in the response.\n\n');
end

% =========================================================================
% PART 3 - Ensemble coherence across trials (proposed correction)
% =========================================================================
log('--------------------------------------------------------\n');
log(' PART 3: ENSEMBLE coherence across all trials\n');
log('--------------------------------------------------------\n');

cfge          = [];
cfge.method   = 'coh';
cfge.complex  = 'complex';
connE         = ft_connectivityanalysis(cfge, freq_csd);   % no cfg.trials -> all

ipair = findpair(connE.labelcmb, 'C3', 'C4');
fidx  = connE.freq >= gammaBand(1) & connE.freq <= gammaBand(2);
cohE  = connE.cohspctrm(ipair, fidx);

log('n trials entering estimate                 : %d\n', nTrials);
log('mean |coherency| (ensemble)                : %.6f\n', mean(abs(cohE)));
log('mean |imag(coherency)| (ensemble absimag)  : %.6f\n\n', mean(abs(imag(cohE))));

log('COMPARISON (gamma C3-C4 absimag):\n');
log('   per-trial mean : %.6f\n', nanmean(absimagPerTrial));
log('   ensemble       : %.6f\n', mean(abs(imag(cohE))));
log('   ratio          : %.3f\n\n', nanmean(absimagPerTrial)/mean(abs(imag(cohE))));

% =========================================================================
% PART 4 - Multi-taper variant (K > 1) for reference
% =========================================================================
log('--------------------------------------------------------\n');
log(' PART 4: increased spectral smoothing (K > 1)\n');
log('--------------------------------------------------------\n');

for W = [2 4]
    cfg2            = [];
    cfg2.output     = 'powandcsd';
    cfg2.method     = 'mtmfft';
    cfg2.taper      = 'dpss';
    cfg2.pad        = 'maxperlen';
    cfg2.keeptrials = 'yes';
    cfg2.tapsmofrq  = W;
    cfg2.channel    = 1:21;
    try
        f2 = ft_freqanalysis(cfg2, ft_EEG);
        k2 = NaN;
        if isfield(f2,'cumtapcnt'), k2 = f2.cumtapcnt(1); end

        cfgc2         = [];
        cfgc2.method  = 'coh';
        cfgc2.complex = 'complex';
        cfgc2.trials  = 1;
        c2 = ft_connectivityanalysis(cfgc2, f2);
        ip2 = findpair(c2.labelcmb,'C3','C4');
        fi2 = c2.freq >= gammaBand(1) & c2.freq <= gammaBand(2);

        log('tapsmofrq = %g : K = %g, single-trial |coherency| = %.6f\n', ...
            W, k2, mean(abs(c2.cohspctrm(ip2,fi2))));
    catch ME
        log('tapsmofrq = %g : failed (%s)\n', W, ME.message);
    end
end

log('\n========================================================\n');
log(' SUMMARY FOR THE RESPONSE LETTER\n');
log('========================================================\n');
log('Tapers per trial (original cfg) : %g\n', K);
log('Trials per coherence estimate   : 1 (cfg.trials = t)\n');
log('Observations per estimate       : %g\n', K*1);
log('Single-trial |coherency|        : %.6f\n', nanmean(magPerTrial));
log('Ensemble |coherency|            : %.6f\n', mean(abs(cohE)));
if isDegenerate
    log('VERDICT: estimate is degenerate; recomputation required.\n');
else
    log('VERDICT: estimate is non-degenerate; report observation count.\n');
end
log('========================================================\n');

fclose(fid);
fprintf('\nDiagnostic written to:\n  %s\n', outFile);

end % main

% =========================================================================
function logboth(fid, fmt, varargin)
fprintf(fmt, varargin{:});
fprintf(fid, fmt, varargin{:});
end

function idx = findchan(labels, target)
idx = find(strcmpi(labels, target));
if isempty(idx)
    idx = find(contains(upper(labels), upper(target)));
end
if isempty(idx), idx = NaN; end
idx = idx(1);
end

function ip = findpair(labelcmb, a, b)
ip = find( (strcmpi(labelcmb(:,1),a) & strcmpi(labelcmb(:,2),b)) | ...
           (strcmpi(labelcmb(:,1),b) & strcmpi(labelcmb(:,2),a)) );
if isempty(ip)
    ip = find( contains(upper(labelcmb(:,1)),upper(a)) & contains(upper(labelcmb(:,2)),upper(b)) );
end
if ~isempty(ip), ip = ip(1); end
end
