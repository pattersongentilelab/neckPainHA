% code for neck pain Pfizer study

Pfizer_dataBasePath = getpref('neckPainHA','pfizerDataPath');

load([Pfizer_dataBasePath 'PfizerHAdataDec23'])

addpath '/Users/pattersonc/Documents/MATLAB/commonFx'


%% Organize data

data_date = data(data.visit_dt<'2023-12-31',:); % date criteria
data_age = data_date(data_date.age>=6 & data_date.age<18,:); % age criteria
data_start = data_age(data_age.p_current_ha_pattern=='episodic' | data_age.p_current_ha_pattern=='cons_same' | data_age.p_current_ha_pattern=='cons_flare' | ~isnan(data_age.p_pedmidas_score),:); % answered the first question, or pedmidas

data_start.clin_loc = categorical(data_start.clin_loc);

data_start.ageY = floor(data_start.age);
% Reorder race categories to make white (largest group) the reference groupdata_start.race = reordercats(data_start.race,{'white','black','asian','am_indian','pacific_island','no_answer','unk'});
data_start.raceFull = reordercats(data_start.race,{'white','black','asian','am_indian','pacific_island','no_answer','unk'});
data_start.race = reordercats(data_start.raceFull,{'white','black','asian','am_indian','pacific_island','no_answer','unk'});
data_start.race = mergecats(data_start.race,{'am_indian','pacific_island','no_answer','unk'},'other');
data_start.race(data_start.race=='other') = '<undefined>';
data_start.race = removecats(data_start.race);

% Reorder ethnicity categories to make non-hispanic (largest group) the
% reference group
data_start.ethnicity = reordercats(data_start.ethnicity,{'no_hisp','hisp','no_answer','unk'});
data_start.ethnicity = mergecats(data_start.ethnicity,{'no_answer','unk'},'unk_no_ans');
data_start.ethnicity(data_start.ethnicity=='unk_no_ans') = '<undefined>';
data_start.ethnicity = removecats(data_start.ethnicity);

data_start.overall_ros = sum(table2array(data_start(:,429:435)),2); % questions on overall problems was entered
data_start.eye_ros = sum(table2array(data_start(:,436:443)),2); % questions on ophtho problems was entered
data_start.ent_ros = sum(table2array(data_start(:,444:454)),2); % questions on ENT problems was entered
data_start.heart_ros = sum(table2array(data_start(:,455:464)),2); % questions on cardiac problems was entered
data_start.lung_ros = sum(table2array(data_start(:,465:472)),2); % questions on pulm problems was entered
data_start.sleep_ros = sum(table2array(data_start(:,473:480)),2); % questions on sleep problems was entered
data_start.gi_ros = sum(table2array(data_start(:,481:488)),2); % questions on GI problems was entered
data_start.gu_ros = sum(table2array(data_start(:,489:496)),2); % questions on gu problems was entered
data_start.musc_ros = sum(table2array(data_start(:,497:504)),2); % questions on musc problems was entered
data_start.skin_ros = sum(table2array(data_start(:,505:510)),2); % questions on derm problems was entered
data_start.endo_ros = sum(table2array(data_start(:,511:518)),2); % questions on endo problems was entered
data_start.hema_ros = sum(table2array(data_start(:,517:525)),2); % questions on heme problems was entered
data_start.immu_ros = sum(table2array(data_start(:,526:533)),2); % questions on immuno problems was entered
data_start.psych_ros = sum(table2array(data_start(:,534:546)),2); % questions on psychiatric diagnoses was entered
data_start.neuro_ros = sum(table2array(data_start(:,547:562)),2); % questions on neuro problems was entered



% Pedmidas, main outcome variable, convert PedMIDAS score to grade
data_start.pedmidas_grade = NaN*ones(height(data_start),1);
data_start.pedmidas_grade(data_start.p_pedmidas_score<=10) = 1;
data_start.pedmidas_grade(data_start.p_pedmidas_score>10 & data_start.p_pedmidas_score<=30) = 2;
data_start.pedmidas_grade(data_start.p_pedmidas_score>30 & data_start.p_pedmidas_score<=50) = 3;
data_start.pedmidas_grade(data_start.p_pedmidas_score>50) = 4;

% Categorize main predictor variable, anxiety only, depression only, both,
% neither
data_start.anxdep = NaN*ones(height(data_start),1);
data_start.anxdep(data_start.p_psych_prob___anxiety==0 & data_start.p_psych_prob___depress==0 & data_start.psych_ros>0) = 0;
data_start.anxdep(data_start.p_psych_prob___anxiety==1 & data_start.p_psych_prob___depress==0 & data_start.psych_ros>0) = 1;
data_start.anxdep(data_start.p_psych_prob___anxiety==0 & data_start.p_psych_prob___depress==1 & data_start.psych_ros>0) = 2;
data_start.anxdep(data_start.p_psych_prob___anxiety==1 & data_start.p_psych_prob___depress==1 & data_start.psych_ros>0) = 3;
data_start.anxdep2 = data_start.anxdep;
data_start.anxdep = categorical(data_start.anxdep,[0 1 2 3],{'neither','anxiety','depression','anxietydepression'});
data_start.anxdepBin = data_start.anxdep2;
data_start.anxdepBin(data_start.anxdepBin>0) = 1;


data_start.anxiety = NaN*ones(height(data_start),1);
data_start.anxiety(data_start.p_psych_prob___anxiety==0) = 0;
data_start.anxiety(data_start.p_psych_prob___anxiety==1) = 1;

data_start.depression = NaN*ones(height(data_start),1);
data_start.depression(data_start.p_psych_prob___depress==0) = 0;
data_start.depression(data_start.p_psych_prob___depress==1) = 1;

% Determine who has seen a behavioral health provider
data_start.bh_provider (data_start.p_psych_prob___sw==1|data_start.p_psych_prob___psychol==1|data_start.p_psych_prob___psychi==1) = 1;

% Determine daily/continuous headache
data_start.dailycont = zeros(height(data_start),1);
data_start.dailycont(data_start.p_current_ha_pattern=='cons_same' | data_start.p_current_ha_pattern=='cons_flare' | data_start.p_fre_bad=='daily' | data_start.p_fre_bad=='always') = 1;

% rank bad headache frequency
data_start.freq_bad = NaN*ones(height(data_start),1);
data_start.freq_bad (data_start.p_fre_bad=='never') = 1;
data_start.freq_bad (data_start.p_fre_bad=='1mo') = 2;
data_start.freq_bad (data_start.p_fre_bad=='1to3mo') = 3;
data_start.freq_bad (data_start.p_fre_bad=='1wk') = 4;
data_start.freq_bad (data_start.p_fre_bad=='2to3wk') = 5;
data_start.freq_bad (data_start.p_fre_bad=='3wk') = 6;
data_start.freq_bad (data_start.p_fre_bad=='daily') = 7;
data_start.freq_bad (data_start.p_fre_bad=='always') = 8;

% rank severity grade
data_start.severity_grade = NaN*ones(height(data_start),1);
data_start.severity_grade(data_start.p_sev_overall=='mild') = 1;
data_start.severity_grade(data_start.p_sev_overall=='mod') = 2;
data_start.severity_grade(data_start.p_sev_overall=='sev') = 3;

% Headache diagnosis and pain quality types
ICHD3 = ichd3_Dx(data_start);
ICHD3.dx = reordercats(ICHD3.dx,{'migraine','prob_migraine','chronic_migraine','tth','chronic_tth','tac','other_primary','new_onset','ndph','pth','undefined'});
data_start.ichd3Full = ICHD3.dx;
ICHD3.dx = mergecats(ICHD3.dx,{'migraine','prob_migraine','chronic_migraine'});
ICHD3.dx = mergecats(ICHD3.dx,{'tth','chronic_tth'});
ICHD3.dx = mergecats(ICHD3.dx,{'ndph','new_onset'});
ICHD3.dx = mergecats(ICHD3.dx,{'other_primary','tac'});
data_start.ichd3 = ICHD3.dx;
data_start.pulsate = ICHD3.pulsate;
data_start.pressure = ICHD3.pressure;
data_start.neuralgia = ICHD3.neuralgia;
data_start.ICHD_data = sum(table2array(ICHD3(:,2:40)),2);

% determine total count for triggers (overall 23 total possible)
data_start.triggerN = sum(table2array(data_start(:,199:221)),2);

% determine total count for associated symptoms
data_start.assocSxN = sum(table2array(data_start(:,[240:241 277 279 282:289 291 292])),2);

data_comp = data_start(data_start.psych_ros>0 & ~isnan(data_start.p_pedmidas_score),:);
data_incomp = data_start(data_start.psych_ros==0 | isnan(data_start.p_pedmidas_score),:);

data_comp.complete = ones(height(data_comp),1);
data_incomp.complete = zeros(height(data_incomp),1);

comp_incomp = [data_comp;data_incomp];

comp_incomp.anxdep(isundefined(comp_incomp.anxdep)) = 'missing';
%% Univariate analysis of primary predictor with covariates
% predictor variable: presence of anxiety and/or depression
[pAgeAnx,tblAgeAnx,statsAgeAnx] = kruskalwallis(data_comp.ageY,data_comp.anxdep);
[tblSexAnx,ChiSexAnx,pSexAnx] = crosstab(data_comp.gender,data_comp.anxdep);
[tblRaceAnx,ChiRaceAnx,pRaceAnx] = crosstab(data_comp.race,data_comp.anxdep);
[tblEthAnx,ChiEthAnx,pEthAnx] = crosstab(data_comp.ethnicity,data_comp.anxdep);
[tblBHanx,ChiBHanx,pBHanx] = crosstab(data_comp.bh_provider,data_comp.anxdep);
[pSevAnx,tblSevAnx,statsSevAnx] = kruskalwallis(data_comp.severity_grade,data_comp.anxdep);
[pFreqAnx,tblFreqAnx,statsFreqAnx] = kruskalwallis(data_comp.freq_bad,data_comp.anxdep);
[tblDCanx,ChiDCanx,pDCanx] = crosstab(data_comp.dailycont,data_comp.anxdep);
[pTrigAnx,tblTrigAnx,statsTrigAnx] = kruskalwallis(data_comp.triggerN,data_comp.anxdep);
[pASxAnx,tblASxAnx,statsASxAnx] = kruskalwallis(data_comp.assocSxN,data_comp.anxdep);
[tblICHDanx,ChiICHDanx,pICHDanx] = crosstab(data_comp.ichd3,data_comp.anxdep);
[tblAdhdAnx,ChiAdhdAnx,pAdhdAnx] = crosstab(data_comp.p_psych_prob___adhd,data_comp.anxdep);

% Outcome variable
mdl_pedmidasSex = fitlm(data_comp,'p_pedmidas_score ~ gender','RobustOpts','on');
tbl_PMsex = lm_tbl_plot(mdl_pedmidasSex);

mdl_pedmidasAge = fitlm(data_comp,'p_pedmidas_score ~ age','RobustOpts','on');
tbl_PMage = lm_tbl_plot(mdl_pedmidasAge);

mdl_pedmidasRace = fitlm(data_comp,'p_pedmidas_score ~ race','RobustOpts','on');
tbl_PMrace = lm_tbl_plot(mdl_pedmidasRace);

mdl_pedmidasEthnicity = fitlm(data_comp,'p_pedmidas_score ~ ethnicity','RobustOpts','on');
tbl_PMeth = lm_tbl_plot(mdl_pedmidasEthnicity);

mdl_pedmidasCont = fitlm(data_comp,'p_pedmidas_score ~ dailycont','RobustOpts','on');
tbl_PpedmidasCont = lm_tbl_plot(mdl_pedmidasCont);

mdl_pedmidasAD = fitlm(data_comp,'p_pedmidas_score ~ anxdep','RobustOpts','on');
tbl_pedmidasAD = lm_tbl_plot(mdl_pedmidasAD);

mdl_pedmidasADHD = fitlm(data_comp,'p_pedmidas_score ~ p_psych_prob___adhd','RobustOpts','on');
tbl_pedmidasADHD = lm_tbl_plot(mdl_pedmidasADHD);

mdl_pedmidasFreq = fitlm(data_comp,'p_pedmidas_score ~ freq_bad','RobustOpts','on');
tbl_pedmidasFreq = lm_tbl_plot(mdl_pedmidasFreq);

mdl_pedmidasSev = fitlm(data_comp,'p_pedmidas_score ~ severity_grade','RobustOpts','on');
tbl_pedmidasSev = lm_tbl_plot(mdl_pedmidasSev);

mdl_pedmidasTrig = fitlm(data_comp,'p_pedmidas_score ~ triggerN','RobustOpts','on');
tbl_pedmidasTrig = lm_tbl_plot(mdl_pedmidasTrig);

mdl_pedmidasSx = fitlm(data_comp,'p_pedmidas_score ~ assocSxN','RobustOpts','on');
tbl_pedmidasSx = lm_tbl_plot(mdl_pedmidasSx);

mdl_pedmidasICHD = fitlm(data_comp,'p_pedmidas_score ~ ichd3','RobustOpts','on');
tbl_pedmidasICHD = lm_tbl_plot(mdl_pedmidasICHD);

% multivariable linear regression analysis (primary predictor anxiety/depression, primary outcome pedmidas)
mdl_MdisabilityFull = fitlm(data_comp,'p_pedmidas_score ~ gender + ageY + race + ethnicity + anxdep + p_psych_prob___adhd + dailycont + freq_bad + severity_grade + triggerN + assocSxN + ichd3','RobustOpts','on');
tbl_MdisabilityFull = lm_tbl_plot(mdl_MdisabilityFull);

mdl_MdisabilityFinal = fitlm(data_comp,'p_pedmidas_score ~ gender + ageY + race + ethnicity + anxdep + dailycont + freq_bad + severity_grade + triggerN + assocSxN + ichd3','RobustOpts','on');
tbl_MdisabilityFinal = lm_tbl_plot(mdl_MdisabilityFinal);


%% sub-analysis of behavioral health provider involvement

mdl_pedmidasBH = fitlm(data_comp(data_comp.anxiety==1|data_comp.depression==1,:),'p_pedmidas_score ~ bh_provider','RobustOpts','on');
tbl_pedmidasBH = lm_tbl_plot(mdl_pedmidasBH);

%% compare those who completed enough of the questionnaire to be included, vs. those who had incomplete information

mdl_incomp_age = fitglm(comp_incomp,'complete ~ ageY','Distribution','binomial');
tbl_incomp_age = brm_tbl_plot(mdl_incomp_age);

mdl_incomp_sex = fitglm(comp_incomp,'complete ~ gender','Distribution','binomial');
tbl_incomp_sex = brm_tbl_plot(mdl_incomp_sex);

mdl_incomp_eth = fitglm(comp_incomp,'complete ~ ethnicity','Distribution','binomial');
tbl_incomp_eth = brm_tbl_plot(mdl_incomp_eth);

mdl_incomp_race = fitglm(comp_incomp,'complete ~ race','Distribution','binomial');
tbl_incomp_race = brm_tbl_plot(mdl_incomp_race);


comp_incomp.anxdepMiss = mergecats(comp_incomp.anxdep,{'neither','anxiety','depression','anxietydepression'});
comp_incomp.anxdepMiss = renamecats(comp_incomp.anxdepMiss,{'neither'},{'not missing'});

mdl_incompA_age = fitglm(comp_incomp,'anxdepMiss ~ ageY','Distribution','binomial');
tbl_incompA_age = brm_tbl_plot(mdl_incompA_age);

mdl_incompA_sex = fitglm(comp_incomp,'anxdepMiss ~ gender','Distribution','binomial');
tbl_incompA_sex = brm_tbl_plot(mdl_incompA_sex);

mdl_incompA_eth = fitglm(comp_incomp,'anxdepMiss ~ ethnicity','Distribution','binomial');
tbl_incompA_eth = brm_tbl_plot(mdl_incompA_eth);

mdl_incompA_race = fitglm(comp_incomp,'anxdepMiss ~ race','Distribution','binomial');
tbl_incompA_race = brm_tbl_plot(mdl_incompA_race);

mdl_incompA_clinic = fitglm(comp_incomp,'anxdepMiss ~ clin_loc','Distribution','binomial');
tbl_incompA_clinic = brm_tbl_plot(mdl_incompA_clinic);

%% Check minima and maxima

comp_incomp.p_pedmidas_scoreHi = comp_incomp.p_pedmidas_score;
comp_incomp.p_pedmidas_scoreHi(isnan(comp_incomp.p_pedmidas_score)) = 240;

mdl_MdisabilityHi = fitlm(comp_incomp,'p_pedmidas_scoreHi ~ gender + ageY + race + ethnicity + anxdep + dailycont + freq_bad + severity_grade + triggerN + assocSxN + ichd3','RobustOpts','on');
tbl_MdisabilityHi = lm_tbl_plot(mdl_MdisabilityHi);

comp_incomp.p_pedmidas_scoreLo = comp_incomp.p_pedmidas_score;
comp_incomp.p_pedmidas_scoreLo(isnan(comp_incomp.p_pedmidas_score)) = 0;

mdl_MdisabilityLo = fitlm(comp_incomp,'p_pedmidas_scoreLo ~ gender + ageY + race + ethnicity + anxdep + dailycont + freq_bad + severity_grade + triggerN + assocSxN + ichd3','RobustOpts','on');
tbl_MdisabilityLo = lm_tbl_plot(mdl_MdisabilityLo);