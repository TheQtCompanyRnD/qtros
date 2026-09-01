// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for Qt wrappers - Main Dispatcher
@# =======================================================
@# This template processes all interface types (messages, services, actions)
@# and dispatches to appropriate sub-templates
@#
@# Template arguments:
@# - package_name
@# - interface_path
@# - content (IdlContent with Messages, Services, Actions)
@{
from rosidl_parser.definition import Message, Service, Action
from rosidl_generator_qtros2 import get_qt_class_name

# This is a dispatcher - it doesn't output anything directly
# It calls other templates based on what's in the content
}@
@
@#######################################################################
@# Handle Messages
@#######################################################################
@[for message in content.get_elements_of_type(Message)]@
@{
# Generate Qt wrapper for this message
# The actual generation happens in the specific templates
# listed in __init__.py mapping
}@
@[end for]@
@
@#######################################################################
@# Handle Services
@#######################################################################
@[for service in content.get_elements_of_type(Service)]@
@{
# Services have request and response messages
# Generate wrappers for both, plus service client

# Request message wrapper (reuse message template)
request_message = service.request_message
response_message = service.response_message

# The service client template will handle both request/response
# and create the client class
}@
@[end for]@
@
@#######################################################################
@# Handle Actions
@#######################################################################
@[for action in content.get_elements_of_type(Action)]@
@{
# Actions have goal, result, and feedback messages
# Generate wrappers for all three, plus action client

goal_message = action.goal
result_message = action.result
feedback_message = action.feedback

# The action client template will handle all three messages
# and create the client class
}@
@[end for]@
