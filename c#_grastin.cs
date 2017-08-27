/*ОТПРАВКА В GRASTIN НОВЫХ СОБРАНЫХ ЗАКАЗОВ*/

namespace GrastinService
{
    public partial class Service : ServiceBase
    {
        #region Отправка новых заказов.

        public void SendNewOrders(OracleConnection co)
        // Отправка новых заказов в Grastin
        {
            // Создание команды Oracle по получению шапки заказов
            OracleCommand comm = new OracleCommand(storProcHead, co);
            comm.CommandType = CommandType.StoredProcedure;
            comm.Parameters.Add(new OracleParameter("orders", OracleDbType.RefCursor)).Direction = ParameterDirection.Output;

            // Получение массива данных из базы
            OracleDataReader reader = comm.ExecuteReader();

            //Выполнение основной бизнес-логики
            if (reader.HasRows)
            {

                List<order> ord = new List<order>();

                // Заполнение массива заказов
                SetOrders(reader, ord);

                // Переменные для отслеживания заказов с ошибками
                bool error_flag = false;
                string error_d = "";

                foreach (order d in ord)
                {
                    // Установка токена
                    token = d.token;

                    // Создание команды Oracle для получения детализации заказа
                    OracleCommand comm_i = new OracleCommand(storProcItems, co);
                    comm_i.CommandType = CommandType.StoredProcedure;

                    // Заполнение детализации
                    SetItems(comm_i, d);

                    // Формирование Xml-файла            
                    MakeXmlFile(d, pathXML);

                    // Отправка запроса и получение ответа
                    SendXmlWithLog(srvLink, pathXML, pathAnswer, pathError);

                    if (GetDataFromAnswer(pathAnswer, "Status") == "Ok")
                    {
                        // Создание команды Oracle для фиксации в базе успешного добавления заказа в Grastin
                        OracleCommand comm_a = new OracleCommand(storProcFix, co);
                        comm_a.CommandType = CommandType.StoredProcedure;

                        FixAnswerInDB(d.orderno, comm_a);

                        File.AppendAllText(pathError, "Заказ № " + d.orderno + " успешно передан в Grastin. \n\n");
                    }
                    else
                    {
                        string mssg = StringFromFile(pathAnswer);
                        MailPutInQueue(email_list, "Error GRASTIN" + DateTime.Now.ToString("dd.MM.yyyy HH:mm:ss"), mssg, co);
                        File.AppendAllText(pathError, "ОШИБКА в процедуре SendNewOrders: при отправке заказа № " + d.orderno + " не был возвращён \"Ok\". \n\n");
                        error_flag = true;
                        error_d += d.orderno.ToString() + " ";
                    }

                }

                // Отслеживание заказов с ошибками
                if (error_flag)
                {
                    File.Copy(pathError, dir + "error " + DateTime.Now.ToString("yyyy-MM-dd HH-mm-ss") + ".txt");
                    AddLog("При отправке заказов №№ " + error_d + "не был возвращён \"Ok\".");
                }
            }

            else
            {
                File.AppendAllText(pathError, "Нет доступных заказов для отправки. \n\n");
            }

            reader.Close();
        }




        public void SetOrders(OracleDataReader orderReader, List<order> ord)
        // Заполнение полей заказа из данных выборки
        {
            while (orderReader.Read())
            {
                string[] str = new string[orderReader.VisibleFieldCount];
                decimal[] dec = new decimal[2];
                int[] ss = new int[3];

                for (int i = 0; i < orderReader.VisibleFieldCount; i++)
                {
                    switch (i)
                    {
                        case 1:
                            ss[0] = orderReader.GetInt32(i);
                            str[i] = ss[0].ToString();
                            break;
                        case 9:
                            dec[0] = orderReader.GetDecimal(i);
                            str[i] = dec[0].ToString();
                            break;
                        case 10:
                            dec[1] = orderReader.GetDecimal(i);
                            str[i] = dec[1].ToString();
                            break;
                        case 13:
                            ss[1] = orderReader.GetInt32(i);
                            str[i] = ss[1].ToString();
                            break;
                        case 14:
                            ss[2] = orderReader.GetInt32(i);
                            str[i] = ss[2].ToString();
                            break;
                        default:
                            str[i] = orderReader.GetValue(i).ToString();
                            break;
                    }

                    if (str[i].Length == 0) str[i] = "";
                }

                ord.Add(new order(str, dec, ss));
            }
        }




        public void SetItems(OracleCommand comand, order d)
        // Заполнение детализации заказа
        {

            // Передача входного параметра
            OracleParameter param = new OracleParameter();
            param.ParameterName = "PDocN";
            param.OracleDbType = OracleDbType.Int32;
            param.Value = d.orderno;
            param.Direction = ParameterDirection.Input;
            comand.Parameters.Add(param);

            // Установка выходного параметра
            comand.Parameters.Add(new OracleParameter("items", OracleDbType.RefCursor)).Direction = ParameterDirection.Output;

            // Заполнение детализации заказа
            OracleDataReader iReader = comand.ExecuteReader();

            d.goods = new List<good>();
            string code = "";
            string name = "";
            decimal price = 0m;
            int amount = 0;

            while (iReader.Read())
            {
                code = iReader.GetValue(0).ToString();
                name = iReader.GetValue(1).ToString();
                price = iReader.GetDecimal(4);
                amount = iReader.GetInt32(3);

                d.goods.Add(new good(code, name, price, amount));
            }

            iReader.Close();
        }


        public void FixAnswerInDB(int orderno, OracleCommand comand)
        // Изменение статуса заказа в нашей базе
        {
            // Передача входных параметров

            //   - номер заказа в нашей базе
            OracleParameter param_orderno = new OracleParameter();
            param_orderno.ParameterName = "POrderN";
            param_orderno.OracleDbType = OracleDbType.Varchar2;
            param_orderno.Value = orderno.ToString();
            param_orderno.Direction = ParameterDirection.Input;
            comand.Parameters.Add(param_orderno);

            //    - новый этого заказа в Grastin
            OracleParameter param_tracking = new OracleParameter();
            param_tracking.ParameterName = "PTracking";
            param_tracking.OracleDbType = OracleDbType.Varchar2;
            param_tracking.Value = "Fresh" + orderno.ToString();
            param_tracking.Direction = ParameterDirection.Input;
            comand.Parameters.Add(param_tracking);

            comand.ExecuteNonQuery();
        }

        #endregion
    }
}