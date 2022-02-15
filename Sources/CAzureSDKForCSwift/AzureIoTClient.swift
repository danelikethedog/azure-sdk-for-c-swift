import AzureSDKForCSwift

public class AzureIoTClient {
    private(set) var embeddedClient: az_iot_hub_client! = nil

    public init(iothubUrl: String, deviceId: String)
    {
        embeddedClient = az_iot_hub_client();
        
        let iothubPointerString = makeCString(from: iothubUrl)
        let deviceIdString = makeCString(from: deviceId)

        let iothubSpan: az_span = iothubPointerString.withMemoryRebound(to: UInt8.self, capacity: iothubUrl.count) { hubPtr in
            return az_span_create(hubPtr, Int32(iothubUrl.count))
        }
        let deviceIdSpan: az_span = deviceIdString.withMemoryRebound(to: UInt8.self, capacity: deviceId.count) { devPtr in
            return az_span_create(devPtr, Int32(deviceId.count))
        }

        _ = az_iot_hub_client_init(&embeddedClient, iothubSpan, deviceIdSpan, nil)
    }

    private func makeCString(from str: String) -> UnsafeMutablePointer<Int8> {
        let count = str.utf8CString.count
        let result: UnsafeMutableBufferPointer<Int8> = UnsafeMutableBufferPointer<Int8>.allocate(capacity: count)
        _ = result.initialize(from: str.utf8CString)
        return result.baseAddress!
    }

    public func GetUserName() -> String
    {
        var usernameCharArray = [CChar](repeating: 0, count: 50)
        var usernameLength : Int = 0
        
        let _ : az_result = az_iot_hub_client_get_user_name(&self.embeddedClient, &usernameCharArray, 50, &usernameLength )
        
        return String(cString: usernameCharArray)
    }

    public func GetClientID() -> String
    {
        var clientIDCharArray = [CChar](repeating: 0, count: 30)
        var clientIDLength : Int = 0
        
        let _ : az_result = az_iot_hub_client_get_client_id(&self.embeddedClient, &clientIDCharArray, 30, &clientIDLength )
        
        return String(cString: clientIDCharArray)
    }

    public func GetTelemetryPublishTopic() -> String
    {
        var topicCharArray = [CChar](repeating: 0, count: 50)
        var topicLength : Int = 0
        
        let _ : az_result = az_iot_hub_client_telemetry_get_publish_topic(&self.embeddedClient, nil, &topicCharArray, 50, &topicLength )
        
        return String(cString: topicCharArray)
    }

    public func GetC2DSubscribeTopic() -> String
    {
        return AZ_IOT_HUB_CLIENT_C2D_SUBSCRIBE_TOPIC
    }
    
    public func GetMethodsSubscribeTopic() -> String
    {
        return AZ_IOT_HUB_CLIENT_METHODS_SUBSCRIBE_TOPIC
    }
    
    public func GetMethodsResponseTopic(requestID: String, status: Int16) -> String
    {
            var topicCharArray = [CChar](repeating: 0, count: 50)
            var topicLength : Int = 0

            let requestIDString = makeCString(from: requestID)
            let requestIDSpan: az_span = requestIDString.withMemoryRebound(to: UInt8.self, capacity: requestID.count) { reqIDPtr in
                return az_span_create(reqIDPtr, Int32(requestID.count))
            }

            let _ : az_result = az_iot_hub_client_methods_response_get_publish_topic(&self.embeddedClient, requestIDSpan, UInt16(status), &topicCharArray, 50, &topicLength )

            return String(cString: topicCharArray)
    }

    public func GetTwinResponseSubscribeTopic() -> String
    {
        return AZ_IOT_HUB_CLIENT_TWIN_RESPONSE_SUBSCRIBE_TOPIC
    }

    public func GetTwinPatchSubscribeTopic() -> String
    {
        return AZ_IOT_HUB_CLIENT_TWIN_PATCH_SUBSCRIBE_TOPIC
    }

    public func GetTwinDocumentPublishTopic(requestID: String) -> String
    {
        var topicCharArray = [CChar](repeating: 0, count: 50)
        var topicLength : Int = 0

        let requestIDString = makeCString(from: requestID)
        let requestIDSpan: az_span = requestIDString.withMemoryRebound(to: UInt8.self, capacity: requestID.count) { reqIDPtr in
            return az_span_create(reqIDPtr, Int32(requestID.count))
        }

        let _ : az_result = az_iot_hub_client_twin_document_get_publish_topic(&self.embeddedClient, requestIDSpan, &topicCharArray, 50, &topicLength )

        return String(cString: topicCharArray)
    }

    public func GetDeviceProvisioningSubscribeTopic() -> String
    {
        return AZ_IOT_PROVISIONING_CLIENT_REGISTER_SUBSCRIBE_TOPIC
    }

}
