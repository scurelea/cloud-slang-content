#   (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#   All rights reserved. This program and the accompanying materials
#   are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
#   The Apache License is available at
#   http://www.apache.org/licenses/LICENSE-2.0
#
####################################################
# Retrieves a list of OpenStack images with IDs, names, and links.
#
# Inputs:
#   - host - OpenStack machine host
#   - identity_port - optional - port used for OpenStack authentication - Default: '5000'
#   - compute_port - optional - port used for OpenStack computations - Default: '8774'
#   - tenant_name - name of OpenStack project that contains images to be retrieved
#   - username - optional - username used for URL authentication; for NTLM authentication,
#                           -Format: 'domain\user'
#   - password - optional - password used for URL authentication
#   - proxy_host - optional - proxy server used to access OpenStack services
#   - proxy_port - optional - proxy server port used to access OpenStack services - Default: '8080'
#   - proxy_username - optional - user name used when connecting to proxy
#   - proxy_password - optional - proxy server password associated with <proxy_username> input value
# Outputs:
#   - return_result - response of operation in case of success, error message otherwise
#   - error_message - return_result if status_code is not '200'
#   - return_code - '0' if success, '-1' otherwise
#   - status_code - code returned by operation
#   - images_list - list of images
# Results:
#   - SUCCESS - list with images were successfully retrieved
#   - GET_AUTHENTICATION_TOKEN_FAILURE - authentication token cannot be obtained
#                                        from authentication call response
#   - GET_TENANT_ID_FAILURE - tenant_id corresponding to tenant_name cannot be obtained
#                             from authentication call response
#   - GET_AUTHENTICATION_FAILURE - authentication call fails
#   - LIST_IMAGES_FAILURE - REST API call to get list of images failed
#   - EXTRACT_IMAGES_FAILURE - list with images could not be retrieved from list images REST API call
####################################################

namespace: io.cloudslang.openstack.images

imports:
  openstack: io.cloudslang.openstack
  rest: io.cloudslang.base.network.rest
  utils: io.cloudslang.openstack.utils

flow:
  name: list_images
  inputs:
    - host
    - identity_port: '5000'
    - compute_port: '8774'
    - tenant_name
    - username:
        required: false
    - password:
        required: false
    - proxy_host:
        required: false
    - proxy_port:
        default: '8080'
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false

  workflow:
    - authentication:
        do:
          openstack.get_authentication_flow:
            - host
            - identity_port
            - tenant_name
            - username
            - password
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
        publish:
          - token
          - tenant_id
          - return_result
          - error_message
        navigate:
          SUCCESS: list_images
          GET_AUTHENTICATION_TOKEN_FAILURE: GET_AUTHENTICATION_TOKEN_FAILURE
          GET_TENANT_ID_FAILURE: GET_TENANT_ID_FAILURE
          GET_AUTHENTICATION_FAILURE: GET_AUTHENTICATION_FAILURE

    - list_images:
        do:
          rest.http_client_get:
            - url: ${'http://'+ host + ':' + compute_port + '/v2/' + tenant_id + '/images'}
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - headers: ${'X-AUTH-TOKEN:' + token}
            - content_type: 'application/json'
        publish:
          - return_result
          - error_message
          - return_code
          - status_code
        navigate:
          SUCCESS: extract_images
          FAILURE: LIST_IMAGES_FAILURE

    - extract_images:
        do:
          utils.extract_object_list_from_json_response:
            - response_body: ${return_result}
            - object_name: 'images'
        publish:
          - images_list: ${object_list}
          - error_message
        navigate:
          SUCCESS: SUCCESS
          FAILURE: EXTRACT_IMAGES_FAILURE

  outputs:
    - return_result
    - error_message
    - return_code
    - status_code
    - images_list

  results:
    - SUCCESS
    - GET_AUTHENTICATION_TOKEN_FAILURE
    - GET_TENANT_ID_FAILURE
    - GET_AUTHENTICATION_FAILURE
    - LIST_IMAGES_FAILURE
    - EXTRACT_IMAGES_FAILURE
