% This file is part of DAVE, a MATLAB toolbox for data evaluation.
% Copyright (C) 2018-2019 Saarland University, Author: Manuel Bastuck
% Website/Contact: www.lmt.uni-saarland.de, info@lmt.uni-saarland.de
% 
% The author thanks Tobias Baur, Tizian Schneider, and Jannis Morsch
% for their contributions.
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
% 
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>. 

function info = svr()
    info.type = DataProcessingBlockTypes.Regression;
    info.caption = 'Support Vector Regression';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','trained', 'value',false, 'internal',true)...
        Parameter('shortCaption','mdl', 'internal',true)...
        Parameter('shortCaption','nComp', 'value',int32(1), 'enum',1:20, 'selection','multiple'),...
        Parameter('shortCaption','projectedData', 'value',[], 'internal',true),...
        ];
    info.apply = @apply;
    info.train = @train;
    info.detailsPages = {'calibration','predictionOverTime','coefficients'};
    info.requiresNumericTarget = true;
end
function [params] = train(data,params,rank)
%            [data, this.mu, this.sigma] = zscore(data);        
%             if ~isnumeric(target) || any(isnan(target))
%                 error('PLSR requires numeric target.');
%             end
%             if numel(unique(target)) <= 1
%                 error('PLSR requires at least two different target values.');
%             end
%             if numel(target) < nComp
%                 error('PLSR requires more observations than components.');
%             end
    try
      help = single(data.data(data.trainingSelection,:));
      d = help(:,rank);
      target = cat2num(data.target(data.trainingSelection));
      nans = isnan(d);
      if any(any(nans))
        warning('%d feature values were NaN and have been replaced with 0.',sum(sum(nans)));
        d(nans) = 0;
      end

      mdl = fitrlinear(d, target, 'Learner','svm', 'Regularization', 'lasso', 'Solver', 'sparsa');
    catch e
        disp(e);
    end
%             this.beta0 = b;
    try
    params.mdl = mdl;
    catch e
        disp(e);
    end
end
function [data, params] = apply(data,params,rank)

    if strcmp(data.mode, 'training')
        help = single(data.data(data.trainingSelection,:));
        dataH = help(:,rank);
    elseif strcmp(data.mode, 'validation')
        help = single(data.data(data.validationSelection,:));
        dataH = help(:,rank);
    end

    pred = predict(params.mdl,dataH);
    params.pred = pred;

    switch data.mode
    case 'training'
        params.projectedData.training = pred;
    end

    try
        data.setSelectedPrediction(pred);
    catch
        params.pred = pred;
    end 
end