import AzureSDKForCSwift

public struct AzureIoTProvisioningRegistrationState
{
    var AssignedHubHostname: String
    var DeviceID: String
    var ErrorCode: az_iot_status
    var ExtendedErrorCode: UInt32
    var ErrorMessage: String
    var ErrorTrackingID: String
    var ErrorTimestamp: String
    
    init(embeddedRegistrationState: az_iot_provisioning_client_registration_state )
    {
        let AssignedHubArray = [CChar](repeating: 0, count: Int(az_span_size(embeddedRegistrationState.assigned_hub_hostname) + 1))
        let AssignedHubString = String(cString: AssignedHubArray)

        let DeviceIDArray = [CChar](repeating: 0, count: Int(az_span_size(embeddedRegistrationState.device_id) + 1))
        let DeviceIDString = String(cString: DeviceIDArray)

        let ErrorMessageArray = [CChar](repeating: 0, count: Int(az_span_size(embeddedRegistrationState.error_message) + 1))
        let ErrorMessageString = String(cString: ErrorMessageArray)
        
        let ErrorTrackingIDArray = [CChar](repeating: 0, count: Int(az_span_size(embeddedRegistrationState.error_tracking_id) + 1))
        let ErrorTrackingIDString = String(cString: ErrorTrackingIDArray)
        
        let ErrorTimestampArray = [CChar](repeating: 0, count: Int(az_span_size(embeddedRegistrationState.error_timestamp) + 1))
        let ErrorTimestampString = String(cString: ErrorTimestampArray)
        
        self.AssignedHubHostname = AssignedHubString
        self.DeviceID = DeviceIDString
        self.ErrorCode = embeddedRegistrationState.error_code
        self.ExtendedErrorCode = embeddedRegistrationState.extended_error_code
        self.ErrorMessage = ErrorMessageString
        self.ErrorTrackingID = ErrorTrackingIDString
        self.ErrorTimestamp = ErrorTimestampString
    }
}

public struct AzureIoTProvisioningRegisterResponse
{
    var OperationID: String
    var Status: az_iot_status
    var OperationStatus: az_iot_provisioning_client_operation_status
    var RetryAfterSeconds: UInt32
    var RegistrationState: AzureIoTProvisioningRegistrationState
    
    init(embeddedResponse: az_iot_provisioning_client_register_response)
    {
        let opID = [CChar](repeating: 0, count: Int(az_span_size(embeddedResponse.operation_id) + 1))
        let opIDString = String(cString: opID)
        
        self.OperationID = opIDString
        self.Status = embeddedResponse.status
        self.OperationStatus = embeddedResponse.operation_status
        self.RetryAfterSeconds = embeddedResponse.retry_after_seconds
        self.RegistrationState = AzureIoTProvisioningRegistrationState(embeddedRegistrationState: embeddedResponse.registration_state)
    }
}

public class AzureIoTClient {
    private(set) var embeddedProvClient: az_iot_provisioning_client! = nil
    private(set) var embeddedHubClient: az_iot_hub_client! = nil

    public init(idScope: String, registrationID: String)
    {
        embeddedHubClient = az_iot_hub_client();

        let globalEndpoint: String = "global.azure-devices-provisioning.net"
        let globalEndpointString = makeCString(from: globalEndpoint)
        let idScopeString = makeCString(from: idScope)
        let registrationIDString = makeCString(from: registrationID)

        let globalEndpointSpan: az_span = globalEndpointString.withMemoryRebound(to: UInt8.self, capacity: globalEndpoint.count) { hubPtr in
            return az_span_create(hubPtr, Int32(globalEndpoint.count))
        }
        let idScopeSpan: az_span = idScopeString.withMemoryRebound(to: UInt8.self, capacity: idScope.count) { hubPtr in
            return az_span_create(hubPtr, Int32(idScope.count))
        }
        let registrationIDSpan: az_span = registrationIDString.withMemoryRebound(to: UInt8.self, capacity: registrationID.count) { devPtr in
            return az_span_create(devPtr, Int32(registrationID.count))
        }

        _ = az_iot_provisioning_client_init(&embeddedProvClient, globalEndpointSpan, idScopeSpan, registrationIDSpan, nil)
    }

    public init(iothubUrl: String, deviceId: String)
    {
        embeddedHubClient = az_iot_hub_client();
        
        let iothubPointerString = makeCString(from: iothubUrl)
        let deviceIdString = makeCString(from: deviceId)

        let iothubSpan: az_span = iothubPointerString.withMemoryRebound(to: UInt8.self, capacity: iothubUrl.count) { hubPtr in
            return az_span_create(hubPtr, Int32(iothubUrl.count))
        }
        let deviceIdSpan: az_span = deviceIdString.withMemoryRebound(to: UInt8.self, capacity: deviceId.count) { devPtr in
            return az_span_create(devPtr, Int32(deviceId.count))
        }

        _ = az_iot_hub_client_init(&embeddedHubClient, iothubSpan, deviceIdSpan, nil)
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
        
        let _ : az_result = az_iot_hub_client_get_user_name(&self.embeddedHubClient, &usernameCharArray, 50, &usernameLength )
        
        return String(cString: usernameCharArray)
    }

    public func GetClientID() -> String
    {
        var clientIDCharArray = [CChar](repeating: 0, count: 30)
        var clientIDLength : Int = 0
        
        let _ : az_result = az_iot_hub_client_get_client_id(&self.embeddedHubClient, &clientIDCharArray, 30, &clientIDLength )
        
        return String(cString: clientIDCharArray)
    }

    public func GetTelemetryPublishTopic() -> String
    {
        var topicCharArray = [CChar](repeating: 0, count: 50)
        var topicLength : Int = 0
        
        let _ : az_result = az_iot_hub_client_telemetry_get_publish_topic(&self.embeddedHubClient, nil, &topicCharArray, 50, &topicLength )
        
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

            let _ : az_result = az_iot_hub_client_methods_response_get_publish_topic(&self.embeddedHubClient, requestIDSpan, UInt16(status), &topicCharArray, 50, &topicLength )

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

        let _ : az_result = az_iot_hub_client_twin_document_get_publish_topic(&self.embeddedHubClient, requestIDSpan, &topicCharArray, 50, &topicLength )

        return String(cString: topicCharArray)
    }

    public func GetDeviceProvisioningSubscribeTopic() -> String
    {
        return AZ_IOT_PROVISIONING_CLIENT_REGISTER_SUBSCRIBE_TOPIC
    }

/// PROVISIONING

    public func GetDeviceProvisionigClientID() -> String {
        var clientIDArray = [CChar](repeating: 0, count: 50)
        var clientIDLength : Int = 0
        
        let _ : az_result = az_iot_provisioning_client_get_client_id(&self.embeddedProvClient, &clientIDArray, 50, &clientIDLength )
        
        return String(cString: clientIDArray)
    }

    public func GetDeviceProvisioningUsername() -> String 
    {
        var UsernameArray = [CChar](repeating: 0, count: 50)
        var UsernameLength : Int = 0
        
        let _ : az_result = az_iot_provisioning_client_get_client_id(&self.embeddedProvClient, &UsernameArray, 50, &UsernameLength )
        
        return String(cString: UsernameArray)
    }

    public func GetDeviceProvisioningRegistrationPublishTopic() -> String
    {
        var TopicArray = [CChar](repeating: 0, count: 50)
        var TopicLength : Int = 0
        
        let _ : az_result = az_iot_provisioning_client_register_get_publish_topic(&self.embeddedProvClient, &TopicArray, 50, &TopicLength )
        
        return String(cString: TopicArray)
    }

    public func ParseRegistrationTopicAndPayload(topic: String, payload: String) -> AzureIoTProvisioningRegisterResponse
    {
        let topicString = makeCString(from: topic)
        let topicSpan: az_span = topicString.withMemoryRebound(to: UInt8.self, capacity: topic.count) { topicPtr in
            return az_span_create(topicPtr, Int32(topic.count))
        }

        let payloadString = makeCString(from: payload)
        let payloadSpan: az_span = payloadString.withMemoryRebound(to: UInt8.self, capacity: payload.count) { payloadPtr in
            return az_span_create(payloadPtr, Int32(payload.count))
        }

        var embeddedRequestResponse: az_iot_provisioning_client_register_response!
        _ = az_iot_provisioning_client_parse_received_topic_and_payload(&self.embeddedProvClient, topicSpan, payloadSpan, &embeddedRequestResponse)
        
        let RequestResponse: AzureIoTProvisioningRegisterResponse = AzureIoTProvisioningRegisterResponse(embeddedResponse: embeddedRequestResponse)
        return RequestResponse
    }

}
