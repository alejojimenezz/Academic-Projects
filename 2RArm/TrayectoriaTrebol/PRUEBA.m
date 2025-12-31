%% PARÁMETROS DEL MECANISMO 2R
L1 = 18; % Longitud eslabón 1 [cm]
L2 = 22; % Longitud eslabón 2 [cm]

%% PARÁMETROS DEL TRÉBOL
num_petalos = 2.5;        % Número de pétalos (3, 4, 5, etc.)
tamano_min = 20;        % Tamaño mínimo del trébol [cm]
factor_escala = 1.2;    % Factor de escala (ajustable)
orientacion = 0.0;        % Orientación en grados (0° = pétalo hacia derecha)
offset_x = 15;           % Desplazamiento horizontal desde origen [cm]
suavizado = 0.05;        % Factor de suavizado (0.2-1.0, menor=más suave)
suavizado_spline = true; % Aplicar suavizado adicional con spline

%% PARÁMETROS DE SIMULACIÓN
num_puntos = 1000;      % Número de puntos en la trayectoria

%% CALCULAR TRÉBOL PARAMETRIZADO
tamano_trebol = tamano_min * factor_escala;
radio_petalos = tamano_trebol / 2;

% Generar puntos del trébol en coordenadas polares
theta_rosa = linspace(0, 2*pi, num_puntos);
r_rosa = radio_petalos * abs(cos(num_petalos * theta_rosa)).^suavizado;

% Convertir a coordenadas cartesianas
x_rosa = r_rosa .* cos(theta_rosa);
y_rosa = r_rosa .* sin(theta_rosa);

% Suavizado adicional con spline si está habilitado
if suavizado_spline
    % Crear más puntos para interpolación suave
    num_puntos_spline = num_puntos * 3;
    theta_spline = linspace(0, 2*pi, num_puntos_spline);
    r_spline = radio_petalos * abs(cos(num_petalos * theta_spline)).^suavizado;
    x_spline = r_spline .* cos(theta_spline);
    y_spline = r_spline .* sin(theta_spline);
    
    % Aplicar spline para suavizar
    t_original = linspace(0, 1, num_puntos_spline);
    t_nuevo = linspace(0, 1, num_puntos);
    x_rosa = spline(t_original, x_spline, t_nuevo);
    y_rosa = spline(t_original, y_spline, t_nuevo);
    
    % Aplicar filtro de media móvil adicional
    window_size = 15;
    x_rosa = movmean(x_rosa, window_size);
    y_rosa = movmean(y_rosa, window_size);
end

% Aplicar rotación (orientación)
ang_rot = deg2rad(orientacion);
x_rot = x_rosa * cos(ang_rot) - y_rosa * sin(ang_rot);
y_rot = x_rosa * sin(ang_rot) + y_rosa * cos(ang_rot);

% Calcular centro del trébol (esquina inferior izquierda + offset)
min_x = min(x_rot);
min_y = min(y_rot);
offset_y = -min_y; % Para que el mínimo Y esté en y=0

% Aplicar desplazamiento
x_trebol = x_rot - min_x + offset_x;
y_trebol = y_rot + offset_y;

%% CINEMÁTICA INVERSA (CODO ABAJO)
theta1 = zeros(1, num_puntos);
theta2 = zeros(1, num_puntos);
alcanzable = true(1, num_puntos);

for i = 1:num_puntos
    x = x_trebol(i);
    y = y_trebol(i);
    
    % Distancia desde origen al punto objetivo
    d = sqrt(x^2 + y^2);
    
    % Verificar si el punto es alcanzable
    if d > (L1 + L2) || d < abs(L1 - L2)
        alcanzable(i) = false;
        fprintf('Punto %d no alcanzable: (%.2f, %.2f), distancia=%.2f cm\n', i, x, y, d);
        continue;
    end
    
    % Ley de cosenos para theta2
    cos_theta2 = (x^2 + y^2 - L1^2 - L2^2) / (2 * L1 * L2);
    cos_theta2 = max(-1, min(1, cos_theta2)); % Limitar a [-1, 1]
    
    % Codo abajo: theta2 negativo (configuración donde el codo está "debajo")
    theta2(i) = -acos(cos_theta2);
    
    % Calcular theta1
    k1 = L1 + L2 * cos(theta2(i));
    k2 = L2 * sin(theta2(i));
    theta1(i) = atan2(y, x) - atan2(k2, k1);
end

%% AÑADIR POSICIÓN INICIAL (HORIZONTAL DERECHA)
% Posición inicial: theta1 = 0° (eslabón 1 horizontal derecha)
%                   theta2 = 0° (eslabón 2 alineado con eslabón 1)
theta1_inicial = deg2rad(0);  % 0° = horizontal hacia la derecha
theta2_inicial = deg2rad(0);  % 0° = extendido, alineado con eslabón 1

% Calcular posición del efector en estado inicial
x_inicial = L1 * cos(theta1_inicial) + L2 * cos(theta1_inicial + theta2_inicial);
y_inicial = L1 * sin(theta1_inicial) + L2 * sin(theta1_inicial + theta2_inicial);

% Número de pasos para la aproximación
num_pasos_aproximacion = 50;

% Crear trayectoria de aproximación desde posición inicial al primer punto
theta1_aprox = linspace(theta1_inicial, theta1(1), num_pasos_aproximacion);
theta2_aprox = linspace(theta2_inicial, theta2(1), num_pasos_aproximacion);

% Calcular posiciones de la trayectoria de aproximación
x_aprox = L1 * cos(theta1_aprox) + L2 * cos(theta1_aprox + theta2_aprox);
y_aprox = L1 * sin(theta1_aprox) + L2 * sin(theta1_aprox + theta2_aprox);

% Concatenar posición inicial + aproximación + trayectoria del trébol
theta1_completo = [theta1_aprox, theta1];
theta2_completo = [theta2_aprox, theta2];
x_completo = [x_aprox, x_trebol];
y_completo = [y_aprox, y_trebol];

% Crear vector de alcanzabilidad extendido
alcanzable_completo = [true(1, num_pasos_aproximacion), alcanzable];

% Actualizar número total de puntos
num_puntos_total = length(theta1_completo);

% Convertir a grados
theta1_deg = rad2deg(theta1_completo);
theta2_deg = rad2deg(theta2_completo);

%% VERIFICAR PUNTOS ALCANZABLES
num_alcanzables = sum(alcanzable_completo);
if num_alcanzables < num_puntos_total
    fprintf('ADVERTENCIA: %d de %d puntos NO son alcanzables\n', ...
            num_puntos_total - num_alcanzables, num_puntos_total);
    fprintf('Considera reducir el tamaño del trébol o ajustar su posición\n\n');
end

%% CINEMÁTICA DIRECTA (VERIFICACIÓN)
x_calculado = L1 * cos(theta1_completo) + L2 * cos(theta1_completo + theta2_completo);
y_calculado = L1 * sin(theta1_completo) + L2 * sin(theta1_completo + theta2_completo);

% Error de verificación
error_x = x_completo - x_calculado;
error_y = y_completo - y_calculado;
error_total = sqrt(error_x.^2 + error_y.^2);
error_max = max(error_total);

fprintf('===== RESULTADOS =====\n');
fprintf('Puntos de aproximación: %d\n', num_pasos_aproximacion);
fprintf('Puntos de trayectoria: %d\n', num_puntos);
fprintf('Puntos totales: %d\n', num_puntos_total);
fprintf('Puntos alcanzables: %d/%d\n', num_alcanzables, num_puntos_total);
fprintf('Error máximo de verificación: %.6f cm\n', error_max);
fprintf('Rango theta1: [%.2f, %.2f] grados\n', min(theta1_deg), max(theta1_deg));
fprintf('Rango theta2: [%.2f, %.2f] grados\n', min(theta2_deg), max(theta2_deg));
fprintf('Posición inicial: theta1=0°, theta2=0° (horizontal derecha, extendido)\n');
fprintf('\n');

%% EXPORTAR DATOS
% Generar vector de tiempo
dt = 0.015; % Paso de tiempo en segundos
tiempo = (0:num_puntos_total-1)' * dt + dt; % Empieza en 0.015

% AJUSTE DE ÁNGULOS PARA ENCODERS
% Posición inicial: theta1 = 0°, theta2 = 0° (horizontal derecha, extendido)
% En esta posición los encoders marcan 0°
% Por lo tanto, los ángulos del encoder son directamente los ángulos calculados
theta1_encoder = theta1_deg - 0;   % theta1_encoder = theta1_deg
theta2_encoder = theta2_deg - 0;   % theta2_encoder = theta2_deg

% Crear tabla con formato solicitado
datos_tabla = array2table([tiempo, theta1_encoder', theta2_encoder'], ...
                          'VariableNames', {'tiempo', 'Theta1', 'Theta2'});

% Exportar a CSV con encabezados
writetable(datos_tabla, 'angulos_motor.csv');

% También guardar datos completos en .mat
datos_completos = [tiempo, x_completo', y_completo', theta1_deg', theta2_deg', theta1_encoder', theta2_encoder'];
save('trayectoria_trebol.mat', 'datos_completos', 'x_completo', 'y_completo', ...
     'theta1_deg', 'theta2_deg', 'theta1_encoder', 'theta2_encoder', ...
     'tiempo', 'alcanzable_completo', 'num_pasos_aproximacion', 'dt');

fprintf('Datos exportados:\n');
fprintf('  - angulos_motor.csv: [tiempo(s), Theta1(deg), Theta2(deg)]\n');
fprintf('  - trayectoria_trebol.mat: datos completos\n');
fprintf('Paso de tiempo: %.3f segundos\n', dt);
fprintf('Tiempo total: %.3f segundos\n', tiempo(end));
fprintf('\nAJUSTE DE ENCODERS:\n');
fprintf('Posición inicial (theta1=0°, theta2=0°) -> Encoders en 0° (horizontal derecha)\n');
fprintf('Rango encoder Theta1: [%.2f, %.2f] grados\n', min(theta1_encoder), max(theta1_encoder));
fprintf('Rango encoder Theta2: [%.2f, %.2f] grados\n\n', min(theta2_encoder), max(theta2_encoder));

%% VISUALIZACIÓN
figure('Position', [100, 100, 1200, 800]);

% Subplot 1: Trayectoria del trébol
subplot(2, 3, 1);
plot(x_trebol, y_trebol, 'b-', 'LineWidth', 2);
hold on;
plot(0, 0, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k');
plot(x_trebol(1), y_trebol(1), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
plot(x_trebol(end), y_trebol(end), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
grid on;
axis equal;
xlabel('X [cm]');
ylabel('Y [cm]');
title('Trayectoria del Trébol');
legend('Trayectoria', 'Origen', 'Inicio', 'Fin', 'Location', 'best');

% Subplot 2: Ángulos vs tiempo
subplot(2, 3, 2);
plot(1:num_puntos_total, theta1_deg, 'b-', 'LineWidth', 1.5);
hold on;
plot(1:num_puntos_total, theta2_deg, 'r-', 'LineWidth', 1.5);
% Marcar fin de aproximación
xline(num_pasos_aproximacion, '--k', 'Inicio Trébol', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
grid on;
xlabel('Punto');
ylabel('Ángulo [grados]');
title('Ángulos de las Articulaciones');
legend('\theta_1 (base)', '\theta_2 (codo)', 'Location', 'best');

% Subplot 3: Error de verificación
subplot(2, 3, 3);
plot(1:num_puntos_total, error_total*1000, 'k-', 'LineWidth', 1);
grid on;
xlabel('Punto');
ylabel('Error [mm]');
title('Error de Cinemática (Verificación)');

% Subplot 4: Animación del mecanismo (posiciones múltiples)
subplot(2, 3, [4, 5, 6]);
hold on;
grid on;
axis equal;
xlabel('X [cm]');
ylabel('Y [cm]');
title('Configuraciones del Mecanismo 2R');

% Dibujar trayectoria del trébol
plot(x_trebol, y_trebol, 'b--', 'LineWidth', 1, 'Color', [0.7, 0.7, 1]);

% Dibujar trayectoria de aproximación
plot(x_aprox, y_aprox, 'g--', 'LineWidth', 1.5);

% Dibujar posición inicial (horizontal derecha extendido)
x_codo_ini = L1 * cos(theta1_inicial);
y_codo_ini = L1 * sin(theta1_inicial);
x_ef_ini = x_inicial;
y_ef_ini = y_inicial;
plot([0, x_codo_ini], [0, y_codo_ini], 'Color', [0.5, 0, 0.5], 'LineWidth', 3);
plot([x_codo_ini, x_ef_ini], [y_codo_ini, y_ef_ini], 'Color', [0.5, 0, 0.5], 'LineWidth', 3);
plot(x_codo_ini, y_codo_ini, 'o', 'Color', [0.5, 0, 0.5], 'MarkerSize', 6, 'MarkerFaceColor', [0.5, 0, 0.5]);

% Dibujar múltiples configuraciones del mecanismo durante la trayectoria
indices_dibujo = round(linspace(num_pasos_aproximacion+1, num_puntos_total, 20));
colores = jet(length(indices_dibujo));

for idx = 1:length(indices_dibujo)
    i = indices_dibujo(idx);
    if ~alcanzable_completo(i)
        continue;
    end
    
    % Posición del codo
    x_codo = L1 * cos(theta1_completo(i));
    y_codo = L1 * sin(theta1_completo(i));
    
    % Dibujar eslabones
    plot([0, x_codo], [0, y_codo], 'Color', colores(idx,:), 'LineWidth', 1);
    plot([x_codo, x_calculado(i)], [y_codo, y_calculado(i)], ...
         'Color', colores(idx,:), 'LineWidth', 1);
    
    % Dibujar articulaciones
    plot(x_codo, y_codo, 'o', 'Color', colores(idx,:), 'MarkerSize', 4, ...
         'MarkerFaceColor', colores(idx,:));
end

% Dibujar origen
plot(0, 0, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k');
plot(x_inicial, y_inicial, 'mo', 'MarkerSize', 8, 'MarkerFaceColor', 'm');
plot(x_trebol(1), y_trebol(1), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');

% Añadir leyenda del espacio de trabajo
theta_workspace = linspace(0, 2*pi, 100);
x_max_reach = (L1 + L2) * cos(theta_workspace);
y_max_reach = (L1 + L2) * sin(theta_workspace);
plot(x_max_reach, y_max_reach, 'k--', 'LineWidth', 0.5);

fprintf('===== INSTRUCCIONES =====\n');
fprintf('1. Ajusta los parámetros al inicio del script\n');
fprintf('2. Los ángulos están en grados\n');
fprintf('3. Los datos se exportan automáticamente\n');
fprintf('4. Theta1 = 0° y Theta2 = 0° cuando ambos eslabones apuntan hacia abajo\n');
fprintf('5. Rotación positiva = CCW (contra-reloj)\n');

%% ANIMACIÓN DEL MECANISMO
fprintf('\n===== GENERANDO ANIMACIÓN =====\n');
figure('Position', [100, 100, 900, 700]);

% Configurar video (opcional)
% video = VideoWriter('mecanismo_2r_animacion.avi');
% video.FrameRate = 30;
% open(video);

% Parámetros de animación
paso_animacion = 3; % Mostrar cada N puntos para hacer animación más rápida
trail_length = 50;   % Longitud de la estela

for i = 1:paso_animacion:num_puntos_total
    if ~alcanzable_completo(i)
        continue;
    end
    
    clf;
    hold on;
    grid on;
    axis equal;
    
    % Límites del gráfico
    xlim([min([x_completo, -10])-5, max(x_completo)+5]);
    ylim([min([y_completo, -25])-5, max(y_completo)+10]);
    
    % Determinar si estamos en fase de aproximación o trayectoria
    if i <= num_pasos_aproximacion
        fase = 'APROXIMACIÓN';
        color_titulo = [0.8, 0.4, 0];
    else
        fase = 'TRAYECTORIA';
        color_titulo = [0, 0.5, 0];
    end
    
    % Título con información
    title(sprintf('Mecanismo 2R - %s | Punto %d/%d | \\theta_1=%.1f° | \\theta_2=%.1f°', ...
                  fase, i, num_puntos_total, theta1_deg(i), theta2_deg(i)), ...
          'FontSize', 12, 'FontWeight', 'bold', 'Color', color_titulo);
    xlabel('X [cm]', 'FontSize', 11);
    ylabel('Y [cm]', 'FontSize', 11);
    
    % Dibujar trayectoria completa del trébol en gris claro
    plot(x_trebol, y_trebol, 'Color', [0.8, 0.8, 0.8], 'LineWidth', 1.5);
    
    % Dibujar trayectoria de aproximación
    plot(x_aprox, y_aprox, 'g--', 'LineWidth', 2);
    
    % Dibujar posición inicial (horizontal derecha extendido) en morado
    x_codo_ini = L1 * cos(theta1_inicial);
    y_codo_ini = L1 * sin(theta1_inicial);
    plot([0, x_codo_ini], [0, y_codo_ini], 'Color', [0.6, 0, 0.6], 'LineWidth', 3, 'LineStyle', ':');
    plot([x_codo_ini, x_inicial], [y_codo_ini, y_inicial], 'Color', [0.6, 0, 0.6], 'LineWidth', 3, 'LineStyle', ':');
    plot(x_codo_ini, y_codo_ini, 'o', 'Color', [0.6, 0, 0.6], 'MarkerSize', 8, 'MarkerFaceColor', [0.6, 0, 0.6]);
    
    % Dibujar trayectoria recorrida hasta ahora
    if i > 1
        plot(x_completo(1:i), y_completo(1:i), 'b-', 'LineWidth', 2);
    end
    
    % Dibujar estela (trail) del efector final
    start_trail = max(1, i-trail_length);
    if i > start_trail
        plot(x_completo(start_trail:i), y_completo(start_trail:i), ...
             'c-', 'LineWidth', 3, 'Color', [0, 0.8, 1]);
    end
    
    % Calcular posiciones
    x_codo = L1 * cos(theta1_completo(i));
    y_codo = L1 * sin(theta1_completo(i));
    x_ef = x_calculado(i);
    y_ef = y_calculado(i);
    
    % Dibujar espacio de trabajo (círculo de alcance máximo)
    theta_workspace = linspace(0, 2*pi, 100);
    x_max = (L1 + L2) * cos(theta_workspace);
    y_max = (L1 + L2) * sin(theta_workspace);
    plot(x_max, y_max, 'k--', 'LineWidth', 0.5, 'Color', [0.5, 0.5, 0.5]);
    
    % Dibujar eslabón 1 (base a codo)
    plot([0, x_codo], [0, y_codo], 'r-', 'LineWidth', 6);
    
    % Dibujar eslabón 2 (codo a efector final)
    plot([x_codo, x_ef], [y_codo, y_ef], 'b-', 'LineWidth', 6);
    
    % Dibujar articulaciones
    plot(0, 0, 'ko', 'MarkerSize', 15, 'MarkerFaceColor', 'k'); % Base
    plot(x_codo, y_codo, 'go', 'MarkerSize', 12, 'MarkerFaceColor', 'g'); % Codo
    plot(x_ef, y_ef, 'mo', 'MarkerSize', 12, 'MarkerFaceColor', 'm'); % Efector
    
    % Dibujar vectores de los ángulos
    arrow_length = 8;
    quiver(0, 0, arrow_length*cos(theta1_completo(i)), arrow_length*sin(theta1_completo(i)), ...
           0, 'r', 'LineWidth', 2, 'MaxHeadSize', 1);
    
    % Añadir leyenda
    legend('Trayectoria objetivo', 'Aproximación', 'Pos. inicial', '', '', ...
           'Trayectoria recorrida', 'Estela', ...
           'Alcance máximo', 'Eslabón 1', 'Eslabón 2', ...
           'Base', 'Codo', 'Efector final', ...
           'Location', 'northeast', 'FontSize', 8);
    
    % Añadir texto con información adicional
    info_text = sprintf('L1 = %.0f cm\nL2 = %.0f cm\n\nConfig: CODO ABAJO\nInicio: θ1=0°, θ2=0°\n(Horizontal derecha)', L1, L2);
    text(min([x_completo, -10])-3, max(y_completo)+7, info_text, ...
         'FontSize', 9, 'BackgroundColor', 'white', 'EdgeColor', 'black', ...
         'VerticalAlignment', 'top');
    
    drawnow;
    
    % Capturar frame para video (descomentar si se desea guardar)
    % frame = getframe(gcf);
    % writeVideo(video, frame);
    
    pause(0.01); % Pausa para visualizar la animación
end

% close(video); % Cerrar video si se guardó

fprintf('Animación completada!\n');