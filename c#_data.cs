/*КЛАССЫ ДЛЯ ДЕСЕРИАЛИЗАЦИИ СОСТОЯНИЯ ЗАКАЗА*/

namespace Data
{
    [XmlRoot(ElementName = "Place")]
    public class Place
    {
        [XmlAttribute(AttributeName = "Number")]
        public string Number { get; set; } = "";
        [XmlAttribute(AttributeName = "Barcode")]
        public string Barcode { get; set; } = "";
    }

    [XmlRoot(ElementName = "Places")]
    public class Places
    {
        [XmlElement(ElementName = "Place")]
        public List<Place> Place { get; set; }
    }

    [XmlRoot(ElementName = "AgentReport")]
    public class AgentReport
    {
        [XmlElement(ElementName = "AgentReportNumber")]
        public string AgentReportNumber { get; set; } = "";
        [XmlElement(ElementName = "Sum")]
        public string Sum { get; set; } = "";
        [XmlElement(ElementName = "SumRefund")]
        public string SumRefund { get; set; } = "";
        [XmlElement(ElementName = "PaidOrder")]
        public string PaidOrder { get; set; } = "";
        [XmlElement(ElementName = "Commission")]
        public string Commission { get; set; } = "";
        [XmlElement(ElementName = "ShipingCost")]
        public string ShipingCost { get; set; } = "";
        [XmlElement(ElementName = "ShipingCostAdditionally")]
        public string ShipingCostAdditionally { get; set; } = "";
        [XmlElement(ElementName = "DistanceCost")]
        public string DistanceCost { get; set; } = "";
        [XmlElement(ElementName = "SumPayment")]
        public string SumPayment { get; set; } = "";
        [XmlElement(ElementName = "SmsInform")]
        public string SmsInform { get; set; } = "";
    }

    [XmlRoot(ElementName = "Order")]
    public class Order
    {
        [XmlElement(ElementName = "Number")]
        public string Number { get; set; } = "";
        [XmlElement(ElementName = "Status")]
        public string Status { get; set; } = "";
        [XmlElement(ElementName = "SecondStatus")]
        public string SecondStatus { get; set; } = "";
        [XmlElement(ElementName = "StatusDateTime")]
        public string StatusDateTime { get; set; } = "";
        [XmlElement(ElementName = "Weight")]
        public string Weight { get; set; } = "";
        [XmlElement(ElementName = "TrackingNumber")]
        public string TrackingNumber { get; set; } = "";
        [XmlElement(ElementName = "Cost")]
        public string Cost { get; set; } = "";
        [XmlElement(ElementName = "CostPost")]
        public string CostPost { get; set; } = "";
        [XmlElement(ElementName = "Barcode")]
        public string Barcode { get; set; } = "";
        [XmlElement(ElementName = "DeliveryRegion")]
        public string DeliveryRegion { get; set; } = "";
        [XmlElement(ElementName = "GeographicArea")]
        public string GeographicArea { get; set; } = "";
        [XmlElement(ElementName = "ClientName")]
        public string ClientName { get; set; } = "";
        [XmlElement(ElementName = "DateDelivery")]
        public string DateDelivery { get; set; } = "";
        [XmlElement(ElementName = "IsSelfPickup")]
        public string IsSelfPickup { get; set; } = "";
        [XmlElement(ElementName = "IdContract")]
        public string IdContract { get; set; } = "";
        [XmlElement(ElementName = "OrderSumma")]
        public string OrderSumma { get; set; } = "";
        [XmlElement(ElementName = "OrderAssessedSumma")]
        public string OrderAssessedSumma { get; set; } = "";
        [XmlElement(ElementName = "RemainingDaysOfStorage")]
        public string RemainingDaysOfStorage { get; set; }
        [XmlElement(ElementName = "Places")]
        public Places Places { get; set; }
        [XmlElement(ElementName = "GoodsList")]
        public string GoodsList { get; set; } = "";
        [XmlElement(ElementName = "AgentReport")]
        public AgentReport AgentReport { get; set; }
    }

    [XmlRoot(ElementName = "Orders")]
    public class Orders
    {
        [XmlElement(ElementName = "Order")]
        public Order Order { get; set; }
    }
}