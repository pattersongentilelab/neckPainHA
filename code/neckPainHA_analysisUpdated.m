% code for neck pain Pfizer study

Pfizer_dataBasePath = getpref('neckPainHA','pfizerDataPath');

load([Pfizer_dataBasePath 'PfizerHAdataAug23'])

addpath '/Users/pattersonc/Documents/MATLAB/commonFx'

%% load([data_path '/ICDcodes.mat']);

data_pathICD = getpref('assocSxHA','pfizerDataPath');
load([data_pathICD '/ICDcodes.mat']);

Chop_icd = icd;
clear icd

chop_subjects = unique(data.record_id);
temp = cellstr('no dx');
data.ICD = categorical(repmat(temp,height(data),1));
for x = 1:length(chop_subjects)
    
    icd = cellstr(Chop_icd.Dx(ismember(Chop_icd.RecordID,chop_subjects(x))));
    
    
    if ~isempty(icd)
        
        iih = contains(icd,'intracranial hypertension','IgnoreCase',true);
        pseudoT = contains(icd,'pseudotumor','IgnoreCase',true);
        pap = contains(icd,'papilledema','IgnoreCase',true);
        pseudopap = contains(icd,'pseudopapilledema','IgnoreCase',true);
        high_pressure = contains(icd,'elevated intracranial pressure','IgnoreCase',true);
        low_pressure = contains(icd,'intracranial hypotension','IgnoreCase',true);
        leak = contains(icd,'CSF leak','IgnoreCase',true);
        vascular = contains(icd,'cerebrovascular','IgnoreCase',true);
        vascularHA = contains(icd,'vascular headache','IgnoreCase',true);
        bleed = contains(icd,'bleeding in brain','IgnoreCase',true);
        bleed2 = contains(icd,'intracranial hemorrhage','IgnoreCase',true);
        tumor = contains(icd,'brain tumor','IgnoreCase',true);
        Btumor = contains(icd,'brainstem tumor','IgnoreCase',true);
        mass = contains(icd,'intracranial mass','IgnoreCase',true);
        lesion = contains(icd,'brain lesion','IgnoreCase',true);
        wm = contains(icd,'white matter','IgnoreCase',true);
        demyelin = contains(icd,'demyelin','IgnoreCase',true);
        neck_mass = contains(icd,'Neck mass','IgnoreCase',true);
        neck_mass2 = contains(icd,'Localized swelling, mass and lump, neck','IgnoreCase',true);
        neck_mass3 = contains(icd,'Swelling, mass, or lump in head and neck','IgnoreCase',true);
        neck_swell = contains(icd,'Neck swelling','IgnoreCase',true);
        neck_fracture = contains(icd,'neck fracture','IgnoreCase',true);
        neck_abscess = contains(icd,'Abscess of neck','IgnoreCase',true);
        neck_nerve_inj = contains(icd,'Injury of other specified nerves of neck','IgnoreCase',true);


        if sum(leak)>0||sum(low_pressure)>0
            data.ICD(x) = 'intracranial hypotension';
        end
        
        if (sum(pap)>0||sum(iih)>0||sum(pseudoT)>0||sum(high_pressure)>0) && sum(pseudopap)==0
            data.ICD(x) = 'intracranial hypertension';
        end
        
        if sum(bleed)>0||sum(bleed2)>0||sum(vascular)>0||sum(vascularHA)>0
            data.ICD(x) = 'vascular';
        end
        
        if sum(lesion)>0
            data.ICD(x) = 'brain lesion';
        end
        
        if sum(demyelin)>0||sum(wm)>0
            data.ICD(x) = 'white matter';
        end

        if sum(tumor)>0||sum(Btumor)>0||sum(mass)>0
            data.ICD(x) = 'tumor';
        end

        if sum(neck_fracture)>0||sum(neck_nerve_inj)>0
            data.ICD(x) = 'neck fracture/injury';
        end

        if sum(neck_mass)>0||sum(neck_mass2)>0||sum(neck_mass3)>0||sum(neck_swell)>0
            data.ICD(x) = 'neck swelling/mass/abscess';
        end
        
    end
clear icd iih pseudoT mass bleed bleed2 vascular vascularHA tumor Btumor low_pressure leak demyelin wm high_pressure pap neck_mass neck_mass2 neck_mass3 neck_swell neck_fracture neck_nerve_inj
end

%% apply exclusion criteria

data_date = data(data.visit_dt>'2017-06-01' & data.visit_dt<'2023-12-31' & data.ICD=='no dx',:); % date criteria
data_age = data_date(data_date.age>=6 & data_date.age<18,:); % age criteria
data_start = data_age(data_age.p_current_ha_pattern=='episodic' | data_age.p_current_ha_pattern=='cons_same' | data_age.p_current_ha_pattern=='cons_flare',:); % started the questionnaire

% Convert age to years
data_start.ageY = floor(data_start.age);

% Reorder race categories to make white (largest group) the reference group
data_start.raceFull = data_start.race;
data_start.race = reordercats(data_start.race,{'white','black','asian','am_indian','pacific_island','no_answer','unk'});
data_start.race = mergecats(data_start.race,{'am_indian','pacific_island','no_answer','unk'},'other');
data_start.race(data_start.race=='other') = '<undefined>';
data_start.race = removecats(data_start.race);

% Reorder ethnicity categories to make non-hispanic (largest group) the
% reference group
data_start.ethnicity = reordercats(data_start.ethnicity,{'no_hisp','hisp','no_answer','unk'});
data_start.ethnicity = mergecats(data_start.ethnicity,{'no_answer','unk'},'unk_no_ans');
data_start.ethnicity(data_start.ethnicity=='unk_no_ans') = '<undefined>';
data_start.ethnicity = removecats(data_start.ethnicity);

pain_loc = sum(table2array(data_start(:,172:181)),2); % pain location was filled out (neck pain)
assoc_oth_sx = sum(table2array(data_start(:,281:294)),2); % associated symptoms were filled out (neck pain)
data_comp = data_start(pain_loc>0 | assoc_oth_sx>0,:);
data_incomp = data_start(pain_loc==0 & assoc_oth_sx==0,:);

data_comp.complete = ones(height(data_comp),1);
data_incomp.complete = zeros(height(data_incomp),1);

comp_incomp = [data_comp;data_incomp];

%% Define main outcome, and main predictor variables

% Neck pain, main outcome variable
data_comp.neckPain = zeros(height(data_comp),1);
data_comp.neckPain(data_comp.p_location_area___neck==1 | data_comp.p_assoc_sx_oth_sx___neck_pain==1) = 1;

% Daily/continuous headache, main predictor variable
data_comp.dailycont = zeros(height(data_comp),1);
data_comp.dailycont(data_comp.p_current_ha_pattern=='cons_same' | data_comp.p_current_ha_pattern=='cons_flare' | data_comp.p_fre_bad=='daily' | data_comp.p_fre_bad=='always') = 1;

% convert PedMIDAS score to grade
data_comp.pedmidas_grade = NaN*ones(height(data_comp),1);
data_comp.pedmidas_grade(data_comp.p_pedmidas_score<=10) = 0;
data_comp.pedmidas_grade(data_comp.p_pedmidas_score>10 & data_comp.p_pedmidas_score<=30) = 1;
data_comp.pedmidas_grade(data_comp.p_pedmidas_score>30 & data_comp.p_pedmidas_score<=50) = 2;
data_comp.pedmidas_grade(data_comp.p_pedmidas_score>50) = 3;

% rank bad headache frequency
data_comp.freq_bad = NaN*ones(height(data_comp),1);
data_comp.freq_bad (data_comp.p_fre_bad=='never') = 1;
data_comp.freq_bad (data_comp.p_fre_bad=='1mo') = 2;
data_comp.freq_bad (data_comp.p_fre_bad=='1to3mo') = 3;
data_comp.freq_bad (data_comp.p_fre_bad=='1wk') = 4;
data_comp.freq_bad (data_comp.p_fre_bad=='2to3wk') = 5;
data_comp.freq_bad (data_comp.p_fre_bad=='3wk') = 6;
data_comp.freq_bad (data_comp.p_fre_bad=='daily') = 7;
data_comp.freq_bad (data_comp.p_fre_bad=='always') = 8;

% rank severity grade
data_comp.severity_grade = NaN*ones(height(data_comp),1);
data_comp.severity_grade(data_comp.p_sev_overall=='mild') = 1;
data_comp.severity_grade(data_comp.p_sev_overall=='mod') = 2;
data_comp.severity_grade(data_comp.p_sev_overall=='sev') = 3;

% activity as a trigger
data_comp.active = NaN*ones(height(data_comp),1);
data_comp.active(data_comp.p_activity == 'feel_worse' | data_comp.p_trigger___exercise==0) = 1;
data_comp.active((data_comp.p_activity == 'feel_better' | data_comp.p_activity == 'no_change' | data_comp.p_activity == 'move') & data_comp.p_trigger___exercise==0) = 0;

% Determine if valsalva is a trigger for headache
data_comp.valsalva = sum(table2array(data_comp(:,228:230)),2);
data_comp.valsalva(data_comp.valsalva>0) = 1;

% Determine if headache is positional
data_comp.position = zeros(height(data_comp),1);
data_comp.position(data_comp.p_valsalva_position___stand==0 & data_comp.p_valsalva_position___lie==0 & (data_comp.p_valsalva_position___none==1 | data_comp.valsalva==1)) = 1;
data_comp.position(data_comp.p_valsalva_position___stand==1 & data_comp.p_valsalva_position___lie==0) = 2;
data_comp.position(data_comp.p_valsalva_position___stand==0 & data_comp.p_valsalva_position___lie==1) = 3;
data_comp.position(data_comp.p_valsalva_position___stand==1 & data_comp.p_valsalva_position___lie==1) = 4;
data_comp.position = categorical(data_comp.position,[1 2 3 4 0],{'neither','worse_stand','worse_lie','both','missing'});
data_comp.position = removecats(data_comp.position,{'missing'});

% Determine pain laterality
data_comp.pain_lat = zeros(height(data_comp),1);
data_comp.pain_lat(data_comp.p_location_side___left==1 & data_comp.p_location_side___right==0 & data_comp.p_location_side___both==0) = 1;
data_comp.pain_lat(data_comp.p_location_side___left==0 & data_comp.p_location_side___right==1 & data_comp.p_location_side___both==0) = 1;
data_comp.pain_lat(data_comp.p_location_side___left==1 & data_comp.p_location_side___right==1 & data_comp.p_location_side___both==0) = 2;
data_comp.pain_lat(data_comp.p_location_side___left==0 & data_comp.p_location_side___right==0 & data_comp.p_location_side___both==1) = 3;
data_comp.pain_lat(data_comp.p_location_side___left==1 & data_comp.p_location_side___right==1 & data_comp.p_location_side___both==1) = 4;
data_comp.pain_lat(data_comp.p_location_side___left==1 & data_comp.p_location_side___right==0 & data_comp.p_location_side___both==1) = 4;
data_comp.pain_lat(data_comp.p_location_side___left==0 & data_comp.p_location_side___right==1 & data_comp.p_location_side___both==1) = 4;
data_comp.pain_lat(data_comp.p_location_side___cant_desc==1 & data_comp.p_location_side___left==0 & data_comp.p_location_side___right==0 & data_comp.p_location_side___both==0) = 5;
data_comp.pain_lat = categorical(data_comp.pain_lat,[3 1 2 4 5 0],{'bilateral','side_lock','uni_alt','combination','cant_desc','missing'});
data_comp.pain_lat = removecats(data_comp.pain_lat,{'missing'});


% associated symptoms
data_comp.sensory_sensitivity = zeros(height(data_comp),1);
data_comp.sensory_sensitivity(data_comp.p_trigger___light==1 | data_comp.p_assoc_sx_oth_sx___light) = data_comp.sensory_sensitivity(data_comp.p_trigger___light==1 | data_comp.p_assoc_sx_oth_sx___light) + 1;
data_comp.sensory_sensitivity(data_comp.p_trigger___noises==1 | data_comp.p_assoc_sx_oth_sx___sound) = data_comp.sensory_sensitivity(data_comp.p_trigger___noises==1 | data_comp.p_assoc_sx_oth_sx___sound) + 1;
data_comp.sensory_sensitivity(data_comp.p_trigger___smells==1 | data_comp.p_assoc_sx_oth_sx___smell) = data_comp.sensory_sensitivity(data_comp.p_trigger___smells==1 | data_comp.p_assoc_sx_oth_sx___smell) + 1;

data_comp.lighthead = data_comp.p_assoc_sx_oth_sx___lighthead;
data_comp.spinning = data_comp.p_assoc_sx_oth_sx___spinning;
data_comp.balance = data_comp.p_assoc_sx_oth_sx___balance;
data_comp.ringing = data_comp.p_assoc_sx_oth_sx___ringing;
data_comp.thinking = data_comp.p_assoc_sx_oth_sx___think;
data_comp.blurry = data_comp.p_assoc_sx_vis___blur;

data_comp.tingling = zeros(height(data_comp),1);
data_comp.tingling((data_comp.p_assoc_sx_neur_uni___numb==1 | data_comp.p_assoc_sx_neur_uni___tingle==1) & (data_comp.p_assoc_sx_neur_bil___numb==0 & data_comp.p_assoc_sx_neur_bil___tingle==0)) = 1; % unilateral only
data_comp.tingling((data_comp.p_assoc_sx_neur_uni___numb==0 & data_comp.p_assoc_sx_neur_uni___tingle==0) & (data_comp.p_assoc_sx_neur_bil___numb==1 | data_comp.p_assoc_sx_neur_bil___tingle==1)) = 2; % bilateral only
data_comp.tingling((data_comp.p_assoc_sx_neur_uni___numb==1 | data_comp.p_assoc_sx_neur_uni___tingle==1) & (data_comp.p_assoc_sx_neur_bil___numb==1 | data_comp.p_assoc_sx_neur_bil___tingle==1)) = 3; % unilateral both
data_comp.tingling = categorical(data_comp.tingling,[0 1 2 3],{'none','unilateral_only','bilateral_only','both'});


% anxiety and depression
data_comp.psych_ros = sum(table2array(data_comp(:,534:546)),2); % questions on psychiatric diagnoses was entered
data_comp.anx = NaN*ones(height(data_comp),1);
data_comp.anx(data_comp.p_psych_prob___anxiety==0 & data_comp.psych_ros>0) = 0;
data_comp.anx(data_comp.p_psych_prob___anxiety==1 & data_comp.psych_ros>0) = 1;
data_comp.dep = NaN*ones(height(data_comp),1);
data_comp.dep(data_comp.p_psych_prob___depress==0 & data_comp.psych_ros>0) = 0;
data_comp.dep(data_comp.p_psych_prob___depress==1 & data_comp.psych_ros>0) = 1;

data_comp.dysauto = zeros(height(data_comp),1);
data_comp.dysauto(data_comp.p_heart_prob___faint==1 | data_comp.p_heart_prob___pots==1) = 1;

data_comp.abd = zeros(height(data_comp),1);
data_comp.abd(data_comp.p_gi_prob___abd_pain==1) = 1;

%% Headache diagnosis
data_comp.p_con_pattern_duration = categorical(data_comp.p_con_pattern_duration);
data_comp.p_epi_fre_dur = categorical(data_comp.p_epi_fre_dur);

ICHD3 = ichd3_Dx(data_comp);
ICHD3.dx = reordercats(ICHD3.dx,{'migraine','chronic_migraine','prob_migraine','tth','chronic_tth','tac','new_onset','ndph','pth','other_primary','undefined'});
ICHD3.dx = mergecats(ICHD3.dx,{'tth','chronic_tth'});
ICHD3.dx = mergecats(ICHD3.dx,{'ndph','new_onset'});
ICHD3.dx = mergecats(ICHD3.dx,{'migraine','chronic_migraine','prob_migraine'});
ICHD3.dx = mergecats(ICHD3.dx,{'other_primary','tac'});
data_comp.ichd3 = ICHD3.dx;

data_comp.pulsate = ICHD3.pulsate;
data_comp.pressure = ICHD3.pressure;
data_comp.neuralgia = ICHD3.neuralgia;
data_comp.ICHD3dx = ICHD3.dx;

%% Primary predictor (daily/continuous headache)
[pAgeDc,tblAgeDc,statsAgeDc] = kruskalwallis(data_comp.ageY,data_comp.dailycont);
[tblSexDc,ChiSexDc,pSexDc] = crosstab(data_comp.gender,data_comp.dailycont);
[tblRaceDc,ChiRaceDc,pRaceDc] = crosstab(data_comp.race,data_comp.dailycont);
[tblethDc,ChiEthDc,pEthDc] = crosstab(data_comp.ethnicity,data_comp.dailycont);
[tblDxDc,ChiDxDc,pDxDc] = crosstab(data_comp.ICHD3dx,data_comp.dailycont);

% CHECK THIS!
[pSevDc,tblSevDc,statsSevDc] = kruskalwallis(data_comp.ageY,data_comp.severity_grade);
[pFreqDc,tblFreqDc,statsFreqDc] = kruskalwallis(data_comp.ageY,data_comp.freq_bad);
[pDisDc,tblDisDc,statsDisDc] = kruskalwallis(data_comp.ageY,data_comp.pedmidas_grade);
[tblPressureDc,ChiPressureDc,pPressureDc] = crosstab(data_comp.gender,data_comp.pressure);
[tblPulsateDc,ChiPulsateDc,pPulsateDc] = crosstab(data_comp.gender,data_comp.pulsate);
[tblNeuralDc,ChiNeuralDc,pNeuralDc] = crosstab(data_comp.gender,data_comp.neuralgia);
[tblLightheadDc,ChiLightheadDc,pLightheadDc] = crosstab(data_comp.gender,data_comp.lighthead);
[tblRingDc,ChiRingDc,pRingDc] = crosstab(data_comp.gender,data_comp.ringing);
[tblSpinDc,ChiSpinDc,pSpinDc] = crosstab(data_comp.gender,data_comp.spinning);
[tblBalanceDc,ChiBalanceDc,pBalanceDc] = crosstab(data_comp.gender,data_comp.balance);
[tblBlureDc,ChiBlurDc,pBlurDc] = crosstab(data_comp.gender,data_comp.blurry);
[tblThinkDc,ChiThinkDc,pThinkDc] = crosstab(data_comp.gender,data_comp.thinking);
[pSensDc,tblSensDc,statsSensDc] = kruskalwallis(data_comp.ageY,data_comp.sensory_sensitivity);
[tblTingleDc,ChiTingleDc,pTingleDc] = crosstab(data_comp.gender,data_comp.tingling);
[tblActiveDc,ChiActiveDc,pActiveDc] = crosstab(data_comp.gender,data_comp.active);
[tblValsDc,ChiValsDc,pValsDc] = crosstab(data_comp.gender,data_comp.valsalva);
[tblPosDc,ChiPosDc,pPosDc] = crosstab(data_comp.gender,data_comp.position);
[tblLatDc,ChiLatDc,pLatDc] = crosstab(data_comp.gender,data_comp.pain_lat);

%% Primary outcome: logistic regression

% univariable
mdl_age = fitglm(data_comp,'neckPain ~ ageY','Distribution','binomial');
tbl_ageNp = brm_tbl_plot(mdl_age);
mdl_sex = fitglm(data_comp,'neckPain ~ gender','Distribution','binomial');
tbl_sexNp = brm_tbl_plot(mdl_sex);
mdl_race = fitglm(data_comp,'neckPain ~ race','Distribution','binomial');a = ExpCalc95fromSE(table2array(mdl_sex.Coefficients(2,1)),table2array(mdl_sex.Coefficients(2,2)));
tbl_raceNp = brm_tbl_plot(mdl_race);
mdl_ethnicity = fitglm(data_comp,'neckPain ~ ethnicity','Distribution','binomial');
tbl_ethnicityNp = brm_tbl_plot(mdl_ethnicity);
mdl_severity = fitglm(data_comp,'neckPain ~ severity_grade','Distribution','binomial');
tbl_severityNp = brm_tbl_plot(mdl_severity);
mdl_disability = fitglm(data_comp,'neckPain ~ pedmidas_grade','Distribution','binomial');
tbl_disabilityNp = brm_tbl_plot(mdl_disability);
mdl_freq_bad = fitglm(data_comp,'neckPain ~ freq_bad','Distribution','binomial');
tbl_freq_badNp = brm_tbl_plot(mdl_freq_bad);
mdl_cont = fitglm(data_comp,'neckPain ~ dailycont','Distribution','binomial');
tbl_contNp = brm_tbl_plot(mdl_cont);
mdl_pain_lat = fitglm(data_comp,'neckPain ~ pain_lat','Distribution','binomial');
tbl_pain_latNp = brm_tbl_plot(mdl_pain_lat);
mdl_pressure = fitglm(data_comp,'neckPain ~ pressure','Distribution','binomial');
tbl_pressureNp = brm_tbl_plot(mdl_pressure);
mdl_pulsate = fitglm(data_comp,'neckPain ~ pulsate','Distribution','binomial');
tbl_pulsateNp = brm_tbl_plot(mdl_pulsate);
mdl_neuralgia = fitglm(data_comp,'neckPain ~ neuralgia','Distribution','binomial');
tbl_neuralgiaNp = brm_tbl_plot(mdl_neuralgia);
mdl_active = fitglm(data_comp,'neckPain ~ active','Distribution','binomial');
tbl_activeNp = brm_tbl_plot(mdl_active);
mdl_valsalva = fitglm(data_comp,'neckPain ~ valsalva','Distribution','binomial');
tbl_valsalvaNp = brm_tbl_plot(mdl_valsalva);
mdl_position = fitglm(data_comp,'neckPain ~ position','Distribution','binomial');
tbl_positionNp = brm_tbl_plot(mdl_position);
mdl_dx = fitglm(data_comp,'neckPain ~ ICHD3dx','Distribution','binomial');
tbl_dxNp = brm_tbl_plot(mdl_dx);

mdl_lighthead = fitglm(data_comp,'neckPain ~ lighthead','Distribution','binomial');
tbl_lightheadNp = brm_tbl_plot(mdl_lighthead);
mdl_ringing = fitglm(data_comp,'neckPain ~ ringing','Distribution','binomial');
tbl_ringingNp = brm_tbl_plot(mdl_ringing);
mdl_spinning = fitglm(data_comp,'neckPain ~ spinning','Distribution','binomial');
tbl_spinningNp = brm_tbl_plot(mdl_spinning);
mdl_balance = fitglm(data_comp,'neckPain ~ balance','Distribution','binomial');
tbl_balanceNp = brm_tbl_plot(mdl_balance);
mdl_thinking = fitglm(data_comp,'neckPain ~ thinking','Distribution','binomial');
tbl_thinkingNp = brm_tbl_plot(mdl_thinking);
mdl_blurry = fitglm(data_comp,'neckPain ~ blurry','Distribution','binomial');
tbl_blurryNp = brm_tbl_plot(mdl_blurry);
mdl_sensory = fitglm(data_comp,'neckPain ~ sensory_sensitivity','Distribution','binomial');
tbl_sensoryNp = brm_tbl_plot(mdl_sensory);
mdl_tingling = fitglm(data_comp,'neckPain ~ tingling','Distribution','binomial');
tbl_tinglingNp = brm_tbl_plot(mdl_tingling);
mdl_dysauto = fitglm(data_comp,'neckPain ~ dysauto','Distribution','binomial');
tbl_dysautoNp = brm_tbl_plot(mdl_dysauto);
mdl_anx = fitglm(data_comp,'neckPain ~ anx','Distribution','binomial');
tbl_anxNp = brm_tbl_plot(mdl_anx);
mdl_dep = fitglm(data_comp,'neckPain ~ dep','Distribution','binomial');
tbl_depNp = brm_tbl_plot(mdl_dep);
mdl_abd = fitglm(data_comp,'neckPain ~ abd','Distribution','binomial');
tbl_abdNp = brm_tbl_plot(mdl_abd);


% multivariable
mdl_Mult = fitglm(data_comp,...
    ['neckPain ~ ageY + gender + race + ethnicity + dailycont + severity_grade + pedmidas_grade + freq_bad + pain_lat + active + valsalva + position + pulsate + pressure + neuralgia + lighthead + spinning + balance + ringing + thinking' ...
    ' + blurry + sensory_sensitivity + tingling + ICHD3dx + dysauto + abd + anx + dep'],...
    'Distribution','binomial');
tbl_MultNp = brm_tbl_plot(mdl_Mult);


% Remove non-significant covariates (p<0.1)
mdl_MultFinal = fitglm(data_comp,...
    'neckPain ~ ageY + gender + race + dailycont + pedmidas_grade + freq_bad + pain_lat + active + position + pressure + neuralgia + balance + ringing + sensory_sensitivity + tingling + abd',...
    'Distribution','binomial');
tbl_MultFinalNp = brm_tbl_plot(mdl_MultFinal);

%% compare those who completed enough of the questionnaire to be included, vs. those who had incomplete information

mdl_incomp = fitglm(comp_incomp,'complete ~ ageY + gender + race + ethnicity','Distribution','binomial');
tbl_incomp = brm_tbl_plot(mdl_incomp);

[a,b,c] = runstest(data_comp.freq_bad,'ud');
[a2,b2,c2] = runstest(data_comp.p_pedmidas_score,'ud')
