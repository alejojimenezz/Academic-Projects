% --- SCRIPT MAESTRO TRANSMISOR ---
clc;
clear;
close all;

% =========================================================================
% 1. CONFIGURACIÓN
% =========================================================================
com_port = "COM8"; % <--- ¡VERIFICA TU PUERTO!
baud_rate = 115200;
archivo_csv = 'angulos_motor.csv'; 

% =========================================================================
% 2. CARGAR DATOS
% =========================================================================
try
    data = readtable(archivo_csv);
    fprintf('CSV cargado: %d puntos.\n', height(data));
catch
    error('No se encuentra el archivo CSV.');
end

% =========================================================================
% 3. CONECTAR AL ESP32
% =========================================================================
fprintf('Conectando a %s...\n', com_port);
if exist('device','var'), clear device; end
try
    device = serialport(com_port, baud_rate);
    configureTerminator(device, "LF");
    flush(device);
catch
    error('Error conectando. Cierra el Monitor Serial de Arduino.');
end
fprintf('Esperando reinicio del ESP32 (2s)...\n');
pause(2);

% =========================================================================
% 4. INICIALIZACIÓN MATEMÁTICA (LA CLAVE DEL ÉXITO)
% =========================================================================
fprintf('Calculando posición de inicio...\n');

% --- CORRECCIÓN CRÍTICA ---
% Usamos LAS MISMAS fórmulas que en el bucle para el punto inicial (i=1)
q1_inicial_calculado = data.Theta1(1);
q2_inicial_calculado = data.Theta2(1);

fprintf('Posición Inicial Calculada -> Q1: %.2f | Q2: %.2f\n', q1_inicial_calculado, q2_inicial_calculado);
fprintf('Por favor, coloca el robot MANUALMENTE en esa posición visual.\n');
fprintf('Presiona cualquier tecla en la consola para calibrar y arrancar...\n');
pause; % El usuario confirma que el robot está listo

% ENVIAMOS EL PRESET (Comando P)
% Esto le dice al Arduino: "Tu posición actual (donde te puse con la mano) ES ESTA".
cmd_preset = sprintf("P,%.2f,%.2f", q1_inicial_calculado, q2_inicial_calculado);
writeline(device, cmd_preset);
fprintf('Calibración enviada (%s). Esperando 1s...\n', cmd_preset);
pause(1);

% Activamos motores suavemente (Comando T al mismo sitio)
writeline(device, sprintf("T,%.2f,%.2f", q1_inicial_calculado, q2_inicial_calculado));

% =========================================================================
% 5. BUCLE DE TRAYECTORIA
% =========================================================================
fprintf('¡Iniciando movimiento!\n');
dt = mean(diff(data.tiempo(1:10))); 

% Vectores para gráficas
cmd_q1 = zeros(height(data), 1); cmd_q2 = zeros(height(data), 1);
real_q1 = zeros(height(data), 1); real_q2 = zeros(height(data), 1);

flush(device);

for i = 1:height(data) % Empezamos desdoe 1 para que sea suave
    
    % Fórmulas IDÉNTICAS a la inicialización
    q1 = data.Theta1(i); 
    q2 = data.Theta2(i);
    
    cmd_q1(i) = q1;
    cmd_q2(i) = q2;
    
    % 1. Enviar
    writeline(device, sprintf("T,%.2f,%.2f", q1, q2));
    
    % 2. Leer Feedback
    if device.NumBytesAvailable > 0
        try
            rx = readline(device);
            vals = sscanf(rx, "D,%f,%f");
            if length(vals) == 2
                real_q1(i) = vals(1);
                real_q2(i) = vals(2);
            end
        catch
        end
    else
        % Rellenar huecos para gráfica
        if i > 1, real_q1(i)=real_q1(i-1); real_q2(i)=real_q2(i-1); end
    end
    
    pause(1.5*dt);
end

fprintf('Fin del trayecto.\n');
clear device;

% =========================================================================k
% 6. GRÁFICAS
% =========================================================================
figure('Name','Resultados','Color','w');
subplot(2,1,1);
plot(cmd_q1, 'b', 'LineWidth', 2); hold on;
plot(real_q1, 'r--', 'LineWidth', 1);
title('Motor 1 (Q1)'); legend('Comando','Real'); grid on;

subplot(2,1,2);
plot(cmd_q2, 'b', 'LineWidth', 2); hold on;
plot(real_q2, 'r--', 'LineWidth', 1);
title('Motor 2 (Q2)'); legend('Comando','Real'); grid on;