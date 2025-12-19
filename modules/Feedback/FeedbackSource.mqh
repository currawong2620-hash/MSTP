//+------------------------------------------------------------------+
//| FeedbackSource.mqh — FeedbackSource role binder                   |
//| Selects concrete FeedbackSource implementation                     |
//| STRICT MQL5, no #pragma once                                      |
//+------------------------------------------------------------------+
#ifndef __FEEDBACK_SOURCE_MQH__
#define __FEEDBACK_SOURCE_MQH__

//--------------------------------------------------------------------
// Select implementation (change ONLY here)
//--------------------------------------------------------------------
#include "impl/FeedbackSource_Minimal.mqh"

// Role contract:
// void FeedbackSource_Run(const ExecutionResult &results[], int count, Feedback &out);

#endif // __FEEDBACK_SOURCE_MQH__
