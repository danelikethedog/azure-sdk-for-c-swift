import AzureSDKForCSwift

public struct AzureIoTProvisioningRegistrationState
{
    public var AssignedHubHostname: String
    public var DeviceID: String
    public var ErrorCode: az_iot_status
    public var ExtendedErrorCode: UInt32
    public var ErrorMessage: String
    public var ErrorTrackingID: String
    public var ErrorTimestamp: String
    
    init(embeddedRegistrationState: az_iot_provisioning_client_registration_state )
    {
        var AssignedHubString = ""
        if az_span_size(embeddedRegistrationState.assigned_hub_hostname) > 0
        {
            var AssignedHubArray = [CChar](repeating: 0, count: Int(az_span_size(embeddedRegistrationState.assigned_hub_hostname) + 1))
            _ = UnsafeMutablePointer<UInt8>(az_span_ptr(embeddedRegistrationState.assigned_hub_hostname)).withMemoryRebound(to: Int8.self, capacity: Int(az_span_size(embeddedRegistrationState.assigned_hub_hostname))) { charPtr in
                return strncpy(&AssignedHubArray, charPtr, Int(az_span_size(embeddedRegistrationState.assigned_hub_hostname)))
            }
            AssignedHubString = String(cString: AssignedHubArray)
        }

        var DeviceIDString = ""
        if az_span_size(embeddedRegistrationState.device_id) > 0
        {
            var DeviceIDArray = [CChar](repeating: 0, count: Int(az_span_size(embeddedRegistrationState.device_id) + 1))
            _ = UnsafeMutablePointer<UInt8>(az_span_ptr(embeddedRegistrationState.device_id)).withMemoryRebound(to: Int8.self, capacity: Int(az_span_size(embeddedRegistrationState.device_id))) { charPtr in
                return strncpy(&DeviceIDArray, charPtr, Int(az_span_size(embeddedRegistrationState.device_id)))
            }
            DeviceIDString = String(cString: DeviceIDArray)
        }

        var ErrorMessageString = ""
        if az_span_size(embeddedRegistrationState.error_message) > 0
        {
            var ErrorMessageArray = [CChar](repeating: 0, count: Int(az_span_size(embeddedRegistrationState.error_message) + 1))
            _ = UnsafeMutablePointer<UInt8>(az_span_ptr(embeddedRegistrationState.error_message)).withMemoryRebound(to: Int8.self, capacity: Int(az_span_size(embeddedRegistrationState.error_message))) { charPtr in
                return strncpy(&ErrorMessageArray, charPtr, Int(az_span_size(embeddedRegistrationState.error_message)))
            }
            ErrorMessageString = String(cString: ErrorMessageArray)
        }
        
        var ErrorTrackingIDString = ""
        if az_span_size(embeddedRegistrationState.error_tracking_id) > 0
        {
            var ErrorTrackingIDArray = [CChar](repeating: 0, count: Int(az_span_size(embeddedRegistrationState.error_tracking_id) + 1))
            _ = UnsafeMutablePointer<UInt8>(az_span_ptr(embeddedRegistrationState.error_tracking_id)).withMemoryRebound(to: Int8.self, capacity: Int(az_span_size(embeddedRegistrationState.error_tracking_id))) { charPtr in
                return strncpy(&ErrorTrackingIDArray, charPtr, Int(az_span_size(embeddedRegistrationState.error_tracking_id)))
            }
            ErrorTrackingIDString = String(cString: ErrorTrackingIDArray)
        }
        
        var ErrorTimestampString = ""
        if az_span_size(embeddedRegistrationState.error_timestamp) > 0
        {
            var ErrorTimestampArray = [CChar](repeating: 0, count: Int(az_span_size(embeddedRegistrationState.error_timestamp) + 1))
            _ = UnsafeMutablePointer<UInt8>(az_span_ptr(embeddedRegistrationState.error_timestamp)).withMemoryRebound(to: Int8.self, capacity: Int(az_span_size(embeddedRegistrationState.error_timestamp))) { charPtr in
                return strncpy(&ErrorTimestampArray, charPtr, Int(az_span_size(embeddedRegistrationState.error_timestamp)))
            }
            ErrorTimestampString = String(cString: ErrorTimestampArray)
        }
        
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
    public var OperationID: String
    public var Status: az_iot_status
    public var OperationStatus: az_iot_provisioning_client_operation_status
    public var RetryAfterSeconds: UInt32
    public var RegistrationState: AzureIoTProvisioningRegistrationState

    init(embeddedResponse: az_iot_provisioning_client_register_response)
    {
        var opID = [CChar](repeating: 0, count: Int(az_span_size(embeddedResponse.operation_id) + 1))
        _ = UnsafeMutablePointer<UInt8>(az_span_ptr(embeddedResponse.operation_id)).withMemoryRebound(to: Int8.self, capacity: Int(az_span_size(embeddedResponse.operation_id))) { charPtr in
            return strncpy(&opID, charPtr, Int(az_span_size(embeddedResponse.operation_id)))
        }
        
        let opIDString = String(cString: opID)
        
        self.OperationID = opIDString
        self.Status = embeddedResponse.status
        self.OperationStatus = embeddedResponse.operation_status
        self.RetryAfterSeconds = embeddedResponse.retry_after_seconds
        self.RegistrationState = AzureIoTProvisioningRegistrationState(embeddedRegistrationState: embeddedResponse.registration_state)
    }
}

public class AzureIoTDeviceProvisioningClient {
    
    private(set) var embeddedProvClient: az_iot_provisioning_client! = nil
    
    public init(idScope: String, registrationID: String)
    {
        embeddedProvClient = az_iot_provisioning_client();

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
    
    private func makeCString(from str: String) -> UnsafeMutablePointer<Int8> {
        let count = str.utf8CString.count
        let result: UnsafeMutableBufferPointer<Int8> = UnsafeMutableBufferPointer<Int8>.allocate(capacity: count)
        _ = result.initialize(from: str.utf8CString)
        return result.baseAddress!
    }
    
    /// PROVISIONING
    public func GetDeviceProvisioningSubscribeTopic() -> String
    {
        return AZ_IOT_PROVISIONING_CLIENT_REGISTER_SUBSCRIBE_TOPIC
    }

    public func GetDeviceProvisionigClientID() -> String {
        var clientIDArray = [CChar](repeating: 0, count: 100)
        var clientIDLength : Int = 0
        
        let _ : az_result = az_iot_provisioning_client_get_client_id(&self.embeddedProvClient, &clientIDArray, 100, &clientIDLength )
        
        return String(cString: clientIDArray)
    }

    public func GetDeviceProvisioningUsername() -> String
    {
        var UsernameArray = [CChar](repeating: 0, count: 100)
        var UsernameLength : Int = 0
        
        let _ : az_result = az_iot_provisioning_client_get_user_name(&self.embeddedProvClient, &UsernameArray, 100, &UsernameLength )
        
        return String(cString: UsernameArray)
    }

    public func GetDeviceProvisioningRegistrationPublishTopic() -> String
    {
        var TopicArray = [CChar](repeating: 0, count: 100)
        var TopicLength : Int = 0
        
        let _ : az_result = az_iot_provisioning_client_register_get_publish_topic(&self.embeddedProvClient, &TopicArray, 100, &TopicLength )
        
        return String(cString: TopicArray)
    }

    public func GetDeviceProvisioningQueryTopic(operationID: String) -> String
    {
        var TopicArray = [CChar](repeating: 0, count: 150)
        var TopicLength : Int = 0

        let operationIDString = makeCString(from: operationID)
        let operationIDSpan: az_span = operationIDString.withMemoryRebound(to: UInt8.self, capacity: operationID.count) { operationIDPtr in
            return az_span_create(operationIDPtr, Int32(operationID.count))
        }

        let azRes : az_result = az_iot_provisioning_client_query_status_get_publish_topic(&self.embeddedProvClient, operationIDSpan, &TopicArray, 150, &TopicLength )

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

        var embeddedRequestResponse: az_iot_provisioning_client_register_response = az_iot_provisioning_client_register_response()
        _ = az_iot_provisioning_client_parse_received_topic_and_payload(&self.embeddedProvClient, topicSpan, payloadSpan, &embeddedRequestResponse)

        let responseStruct: AzureIoTProvisioningRegisterResponse = AzureIoTProvisioningRegisterResponse(embeddedResponse: embeddedRequestResponse)

        return responseStruct
    }
}

public class AzureIoTHubClient {
    private(set) var embeddedHubClient: az_iot_hub_client! = nil

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
        var usernameCharArray = [CChar](repeating: 0, count: 100)
        var usernameLength : Int = 0
        
        let _ : az_result = az_iot_hub_client_get_user_name(&self.embeddedHubClient, &usernameCharArray, 100, &usernameLength )
        
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
        var topicCharArray = [CChar](repeating: 0, count: 100)
        var topicLength : Int = 0
        
        let _ : az_result = az_iot_hub_client_telemetry_get_publish_topic(&self.embeddedHubClient, nil, &topicCharArray, 100, &topicLength )
        
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
            var topicCharArray = [CChar](repeating: 0, count: 100)
            var topicLength : Int = 0

            let requestIDString = makeCString(from: requestID)
            let requestIDSpan: az_span = requestIDString.withMemoryRebound(to: UInt8.self, capacity: requestID.count) { reqIDPtr in
                return az_span_create(reqIDPtr, Int32(requestID.count))
            }

            let _ : az_result = az_iot_hub_client_methods_response_get_publish_topic(&self.embeddedHubClient, requestIDSpan, UInt16(status), &topicCharArray, 100, &topicLength )

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
        var topicCharArray = [CChar](repeating: 0, count: 100)
        var topicLength : Int = 0

        let requestIDString = makeCString(from: requestID)
        let requestIDSpan: az_span = requestIDString.withMemoryRebound(to: UInt8.self, capacity: requestID.count) { reqIDPtr in
            return az_span_create(reqIDPtr, Int32(requestID.count))
        }

        let _ : az_result = az_iot_hub_client_twin_document_get_publish_topic(&self.embeddedHubClient, requestIDSpan, &topicCharArray, 100, &topicLength )

        return String(cString: topicCharArray)
    }
}
