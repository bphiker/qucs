classdef asynctrcircuit < qucstrans
    % asynchonous circuit solver for use with the ode integrator routines
    % based on an interface to the qucs transient circuit solvers
    %
    %

    % Copyright Richard Crozier 2013

    properties (SetAccess = private, GetAccess = public)
%         
%         t_history;
%         sol_history;
%         
%         hist_length = 2;

    end


    methods

        function this = asynctrcircuit(netlist)

            this = this@qucstrans(netlist);

        end

        function init(this, tstart, firstdelta)
            % initialises the circuit solver

            this.cppcall('init_async', tstart, firstdelta);

            this.isinitialised = true;

        end
        
        function stepsolve(this, t)
            % solves an asynchronous step at the supplied time
            %
            % Syntax
            %
            % stepsolve(this, t)
            %
            % Input
            %
            %   t - the time point at which the circuit simulation is to be
            %   solved
            %
            % Description
            %
            % This function causes the qucs solvers to attempt to solve the
            % circuit at the time t. The result is stored internally, and
            % can be retrieved with the getsolution method. The solution is
            % not added to the history of time steps used by the circuit
            % integrators. To add the solution to the history and move on
            % to the next step, the acceptstep_sync function must be used.
            %

            if ~isscalar(t)
                error('t must be a scalar.');
            end

            this.cppcall('stepsolve_async', t);

        end
        
        function [sol, NM] = getsolution(this)
            % retrieves the last solution generated by the circuit solver
            %
            % Syntax
            %
            % [sol, NM] = getsolution(this)
            %
            % Description
            %
            % getsolution returns an vector containing the nodal voltages
            % and branch currents at the last solution generated by a call
            % to stepsolve acceptstep, or just initialisation. The number
            % of nodal voltages and branch currents respectively are
            % returned in the two element vector NM.
            %

            [sol, NM] = this.cppcall('getsolution');

        end
        
        function acceptstep(this, t)
            % recalculates and accepts a time step solution into the
            % internal history of solutions for the circuit integrators
            %
            % Syntax
            %
            % acceptstep(this, t)
            %
            % Input
            %
            %   t - the time point at which the circuit is to be
            %     recalculated and added to the solution history
            % 

            stepsolve(this, t);

            this.cppcall('acceptstep_async');

%             % push the new t value  and solution onto the history
%             this.t_history = circshift(this.t_history, [0, -1]);
% 
%             this.t_history(end) = t;
% 
%             this.sol_history = circshift(this.sol_history, [0, -1]);
% 
%             this.sol_history(:,end) = this.getsolution();

        end
        
        function rejectstep(this)
            % rejects an asynchronous step, resetting the internal history
            % to the last accepted step
            %
            % Syntax
            %
            % rejectstep(this)
            %

            this.cppcall('rejectstep_async');

        end
        
    end
    
    
    methods(Static)
        
        function status = odeoutputfcn(t, y, flag, qtr_async)
            % static method for updating the asynchronous circuit on each
            % time step of an ode solution
            %
            % Syntax
            %
            % status = odeoutputfcn(t, y, flag, qtr_async)
            %
            % Description
            %
            % This function must be called as the output function, or
            % within the output function of an ode solution incorporating
            % the synchronous circuit solver. See the help for odeset.m for
            % more details on the ode solver OutputFcn option. 
            %
            % 
            
            status = 0;
            
            if isempty(flag)
                % solve and accept the time step into the circuit solution
                % history
                qtr_async.acceptstep(t);

            elseif strcmp(flag, 'init')
                % initialise the circuit
%                 qtr_async.init(t(1));

            elseif strcmp(flag, 'done')
                
%                 qtr_async.
                
            end
            
        end
%         
%         function dydt = odefcn(t, y, qtr_sync)
%             % static method for determining the derivatives of the circuit
%             % solution at each time step for use with the ode solvers
%             %
%             % Syntax
%             %
%             % status = odefcn(t, y, qtr_sync)
%             %
%             
%             % test if the circuit is initialised, this is necessary,
%             % because contrary to what the ode solver documentation states,
%             % the solver function is called before the OutputFcn is ever
%             % called with the 'init' flag in odearguments.m
%             
%             if qtr_sync.isinitialised
%                 % if the circuit is initialised start solving
% 
%                 if qtr_sync.t_history(end) == t
% 
%                     dydt = zeros(length(y),1);
%                     
% % %                     dydt = qtr_sync.dydt_history;
% % 
% %                     fit_time = qtr_sync.t_history(~isnan(qtr_sync.t_history));
% % 
% %                     fit_time = [ fit_time(1:end-1), t ];
% % 
% %                     if numel(fit_time) == 1
% %                         dydt = (qtr_sync.sol_history(:,end-1) - y) ./ (t - fit_time(end - 1));
% %                     else
% % 
% %                         % need to use y in here
% %                         fit_sol = [qtr_sync.sol_history(:,1:end-1), y];
% %                         fit_sol = permute(fit_sol(~isnan(fit_sol)), [ 2, 3, 1 ]);
% % 
% %                         [ ~, p1p2der1 ] = threepntcubicsplinefit(...
% %                                             [ repmat(fit_time, [1, 1, numel(fit_sol)]), fit_sol ]);
% % 
% %                         dydt = squeeze(p1p2der1(2,1,:) .* t.^2 + p1p2der1(2,2,:) .* t + p1p2der1(2,3,:));
% %                     end
% 
%                 else
%                     % attempt to solve the circuit at the current time step
% %                     if t - qtr_sync.t_history(end) < eps
%                     qtr_sync.stepsolve(t);
% 
%                     % get the solution just calculated
%                     sol = qtr_sync.getsolution();
% 
%                     % get the derivative w.r.t.
% 
%                     fit_time = [ qtr_sync.t_history(~isnan(qtr_sync.t_history)), t ]';
% 
%                     if numel(fit_time) == 2
%                         dydt = (sol - y) ./ (t - qtr_sync.t_history(end));
%                     else
%                         fit_sol = permute([ qtr_sync.sol_history(:,1:end), sol ], [ 2, 3, 1 ]);
% 
%                         [ ~, p1p2der1 ] = threepntcubicsplinefit(...
%                                             [ repmat(fit_time, [1, 1, numel(sol)]), fit_sol ] );
% 
%                         dydt = squeeze(p1p2der1(2,1,:) .* t.^2 + p1p2der1(2,2,:) .* t + p1p2der1(2,3,:));
%                     end
% 
%                 end
% 
%             else
%                 dydt = zeros(length(y),1);
%             end
% 
%         end

    end

end