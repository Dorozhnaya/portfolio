/* ОСНОВНОЙ МОДУЛЬ */

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using Oracle.ManagedDataAccess.Client;
using Oracle.ManagedDataAccess.Types;
using System.Xml;
using System.Xml.Serialization;
using System.IO;
using System.Net;
using System.Globalization;
using System.Threading;
using System.Runtime.Serialization.Formatters.Binary;
using Data;

namespace GrastinService
{
    public partial class Service : ServiceBase
    {

#region Установка переменных.

	// Строка соединения с БД
	// Имена хранимых процедур в БД
	// Пути к вспомогательным файлам

#endregion       

#region Запуск службы.

        // Таймер для запуска службы
        public System.Timers.Timer timer = null;

        // Для записи логов в журнал логов приложений
        public EventLog eventLog1;

        public Service()
        {
            InitializeComponent();
            this.CanStop = true;
            this.CanPauseAndContinue = true;

            // Создание директории для вспомогательных файлов
            if (!Directory.Exists(dir))
            {
                Directory.CreateDirectory(dir);
            }
        }

        // Переменная для хранения момента запуска или остановки службы
        public string time = ""; 

        protected override void OnStart(string[] args)
        {
            this.timer = new System.Timers.Timer();
            this.timer.Interval = 600000;
            this.timer.Elapsed += Main_Proc;
            this.timer.AutoReset = true;
            this.timer.Enabled = true;

            // Начало логирования
            time = DateTime.Now.ToString("dd.MM.yyyy HH:mm:ss");
            AddLog("Служба запущена. Время: " + time);
            File.AppendAllText(baseLog, "Служба запущена. Время: " + time + ". \n\n");
        }

        protected override void OnStop()
        {
            this.timer.Stop();
            this.timer = null;

            // Окончание логирования
            time = DateTime.Now.ToString("dd.MM.yyyy HH:mm:ss");
            AddLog("Служба остановлена. Время: " + time);
            File.AppendAllText(baseLog, "Служба остановлена. Время: " + time + ". \n\n");
        }

        public void AddLog(string log)
        {
            try
            {
                if (!EventLog.SourceExists("Grastin_Integration_Service"))
                {
                    EventLog.CreateEventSource("Grastin_Integration_Service", "Grastin_Integration_Service");
                }
                eventLog1.Source = "Grastin_Integration_Service";
                eventLog1.WriteEntry(log);
            }
            catch { }
        }

#endregion        

#region Основная процедура.

        public void Main_Proc(object sender, System.Timers.ElapsedEventArgs e)
        {
            // Начало логирования текущей итерации
            string thisTime = DateTime.Now.ToString("yyyy-MM-dd HH-mm-ss");
            pathError = dir + "log " + thisTime + ".txt";
            File.AppendAllText(pathError, "Старт программы " + thisTime + ". \n\n");

            // Создание подключения к БД
            OracleConnection conn = new OracleConnection(connString);

            // Установка соединения
            conn.Open();
            AddLog("Установлено соединение с БД. Время: " + DateTime.Now.ToString("dd.MM.yyyy HH:mm:ss"));
            File.AppendAllText(pathError, "Установлено соединение с БД. Время: " + DateTime.Now.ToString("HH:mm:ss") + "\n\n");

            try
            {
                // Отправка новых заказов в Grastin
                File.AppendAllText(pathError, "Отправка новых заказов в Grastin. \n\n");
                SendNewOrders(conn);
                File.AppendAllText(pathError, "Отправка заказов отработала. \n\n");
                AddLog("Отправка заказов отработала. Время: " + DateTime.Now.ToString("dd.MM.yyyy HH:mm:ss"));

                // Трекинг
                File.AppendAllText(pathError, "Трекинг. \n\n");
                GetOrderData(conn);
                File.AppendAllText(pathError, "Трекинг отработал. \n\n");
                AddLog("Трекинг отработал. Время: " + DateTime.Now.ToString("dd.MM.yyyy HH:mm:ss"));

                // Гео-проверка
                File.AppendAllText(pathError, "Гео-проверка. \n\n");
                GetDeliverability(conn);
                File.AppendAllText(pathError, "Гео-проверка отработала. \n\n");
                AddLog("Гео-проверка отработала. Время: " + DateTime.Now.ToString("dd.MM.yyyy HH:mm:ss"));
            }

            catch (Exception ex)
            {
                File.AppendAllText(pathError, "Ошибка в процедуре Main: \n");
                File.AppendAllText(pathError, ex.Message + " \n\n");
                File.Copy(pathError, dir + "error " + DateTime.Now.ToString("yyyy-MM-dd HH-mm-ss") + ".txt");
                AddLog("В Main_Proc - catch. " + ex.Message);
                MailPutInQueue(email_list, "Error GRASTIN" + DateTime.Now.ToString("dd.MM.yyyy HH:mm:ss"), ex.Message, conn);
            }

            conn.Close();
            conn.Dispose();

            File.AppendAllText(pathError, "Соединение закрыто. \n\n");
            AddLog("Соединение закрыто. Время: " + DateTime.Now.ToString("dd.MM.yyyy HH:mm:ss"));

            File.Delete(pathXML);
            File.Delete(pathAnswer);
        }

#endregion

    }
}