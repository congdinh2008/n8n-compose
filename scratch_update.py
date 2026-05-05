import json

with open('workflows/quiz_generator_workflow.json', 'r') as f:
    data = json.load(f)

nodes = []

# 1. Google Drive Trigger
nodes.append({
  "parameters": {
    "pollTimes": {
      "item": [{"mode": "everyMinute"}]
    },
    "event": "fileCreated",
    "triggerOn": "any",
    "options": {}
  },
  "id": "eaf76a79-572b-4bd8-a1ba-4fd43f7e42fa",
  "name": "Google Drive Trigger",
  "type": "n8n-nodes-base.googleDriveTrigger",
  "typeVersion": 1,
  "position": [0, 0],
  "credentials": {
    "googleDriveOAuth2Api": {
      "id": "kIn77hC1D3e4d8C0",
      "name": "Google Drive account"
    }
  }
})

# 2. Filter Markdown Files
nodes.append({
  "parameters": {
    "jsCode": """// Lọc chỉ lấy các file Markdown (.md)
const items = $input.all();
const markdownFiles = items.filter(item => {
  const name = item.json.name || '';
  const mimeType = item.json.mimeType || '';
  return name.endsWith('.md') || 
         name.endsWith('.markdown') ||
         mimeType === 'text/markdown' ||
         (mimeType === 'text/plain' && (name.endsWith('.md') || name.endsWith('.markdown')));
});

if (markdownFiles.length === 0) {
  return [];
}

const fileName = markdownFiles[0].json.name;
const quizTitle = fileName.replace(/\\.[^/.]+$/, ""); // Bỏ đuôi file
const questionsPerFile = 15;
const description = 'Bộ câu hỏi chuyên sâu được tạo tự động từ tài liệu ' + fileName;

return markdownFiles.map(item => ({
  json: {
    fileId: item.json.id,
    fileName: item.json.name,
    mimeType: item.json.mimeType,
    quizTitle,
    questionsPerFile,
    description
  }
}));"""
  },
  "id": "c154582a-e638-4acf-99c3-5b6d998d8878",
  "name": "Filter Markdown Files",
  "type": "n8n-nodes-base.code",
  "typeVersion": 2,
  "position": [250, 0]
})

# 3. Search Existing Form API
nodes.append({
  "parameters": {
    "method": "GET",
    "url": "https://www.googleapis.com/drive/v3/files",
    "authentication": "predefinedCredentialType",
    "nodeCredentialType": "googleDriveOAuth2Api",
    "sendQuery": True,
    "queryParameters": {
      "parameters": [
        {
          "name": "q",
          "value": "=mimeType='application/vnd.google-apps.form' and name='{{ $json.quizTitle }}' and trashed=false"
        }
      ]
    },
    "options": {}
  },
  "id": "search-form-node",
  "name": "Search Existing Form API",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "position": [500, 0],
  "credentials": {
    "googleDriveOAuth2Api": {
      "id": "kIn77hC1D3e4d8C0",
      "name": "Google Drive account"
    }
  }
})

# 4. Check If Form Exists
nodes.append({
  "parameters": {
    "jsCode": """const files = $input.first().json.files || [];
if (files.length > 0) {
  console.log('Form đã tồn tại, bỏ qua tạo mới.');
  return []; // Dừng workflow
}
// Nếu chưa có, tiếp tục xử lý file markdown
return [{ json: $('Filter Markdown Files').first().json }];"""
  },
  "id": "check-form-node",
  "name": "Check If Form Exists",
  "type": "n8n-nodes-base.code",
  "typeVersion": 2,
  "position": [750, 0]
})

# 5. Download Markdown File Content
nodes.append({
  "parameters": {
    "operation": "download",
    "fileId": {
      "__rl": True,
      "value": "={{ $json.fileId }}",
      "mode": "id"
    },
    "options": {}
  },
  "id": "ba292c6f-698e-47e6-a6fe-6fcb73691cf6",
  "name": "Download Markdown File Content",
  "type": "n8n-nodes-base.googleDrive",
  "typeVersion": 3,
  "position": [1000, 0],
  "credentials": {
    "googleDriveOAuth2Api": {
      "id": "kIn77hC1D3e4d8C0",
      "name": "Google Drive account"
    }
  }
})

# 6. Extract Text Content
nodes.append({
  "parameters": {
    "jsCode": """const item = $input.first();
const binaryData = item.binary?.data;
const jsonData = item.json;

let markdownContent = '';

if (binaryData) {
  const base64Content = binaryData.data;
  markdownContent = Buffer.from(base64Content, 'base64').toString('utf-8');
} else if (jsonData.data) {
  markdownContent = jsonData.data;
}

const maxLength = 8000;
if (markdownContent.length > maxLength) {
  markdownContent = markdownContent.substring(0, maxLength) + '\\n... [nội dung bị cắt bớt]';
}

return [{
  json: {
    ...jsonData,
    markdownContent,
    contentLength: markdownContent.length
  }
}];"""
  },
  "id": "0fb1559d-75c3-4d1f-b0a9-cd7bce6b3123",
  "name": "Extract Text Content",
  "type": "n8n-nodes-base.code",
  "typeVersion": 2,
  "position": [1250, 0]
})

# 7. AI Generate Quiz Questions
gemini_prompt = '''={{ (() => {
  const systemPrompt = 'Bạn là chuyên gia thiết kế đề thi và kiểm tra chuyên nghiệp. Nhiệm vụ của bạn là đọc tài liệu Markdown và tạo ra các câu hỏi trắc nghiệm chất lượng cao, có độ khó cao, đánh giá sâu sắc sự hiểu biết của người học.\\n\\nYêu cầu:\\n- MỖI QUIZ PHẢI CÓ ÍT NHẤT 15 CÂU HỎI.\\n- Mỗi câu hỏi phải có 4 lựa chọn (A, B, C, D).\\n- Chỉ có 1 đáp án đúng.\\n- CÂU TRẢ LỜI SAI (distractors) phải cực kỳ hợp lý, có tính gây nhiễu cao, dựa trên những lỗi sai phổ biến hoặc sự nhầm lẫn khái niệm. KHÔNG DÙNG CÁC CÂU TRẢ LỜI SAI QUÁ HIỂN NHIÊN HOẶC QUÁ DỄ.\\n- Các câu hỏi không được chỉ hỏi lý thuyết suông, phải đưa vào bối cảnh thực tế (case study) hoặc best practice để người học phải tư duy phân tích, đánh giá chứ không chỉ ghi nhớ.\\n- Không tạo các câu hỏi quá dễ (mức độ biết/hiểu cơ bản). Tập trung vào mức độ vận dụng, phân tích, đánh giá.\\n- Câu hỏi viết bằng tiếng Việt (nếu tài liệu bằng tiếng Việt) hoặc cùng ngôn ngữ với tài liệu.\\n\\nTRẢ LỜI PHẢI LÀ JSON THUẦN TÚY (không có markdown code block), theo định dạng:\\n{\\n  "questions": [\\n    {\\n      "question": "Nội dung câu hỏi tình huống hoặc phân tích?",\\n      "options": {\\n        "A": "Lựa chọn gây nhiễu hợp lý 1",\\n        "B": "Lựa chọn gây nhiễu hợp lý 2",\\n        "C": "Lựa chọn đúng (hoặc nhiễu 3)",\\n        "D": "Lựa chọn còn lại"\\n      },\\n      "correctAnswer": "C",\\n      "explanation": "Giải thích chi tiết tại sao đáp án này là tối ưu nhất và tại sao các đáp án kia dù nghe có vẻ đúng nhưng lại sai trong ngữ cảnh này"\\n    }\\n  ]\\n}';
  const userPrompt = `Tạo ${$json.questionsPerFile || 15} câu hỏi trắc nghiệm chuyên sâu và thực tế từ tài liệu sau:\\n\\n**Tên file:** ${$json.fileName}\\n\\n**Nội dung:**\\n${$json.markdownContent}`;
  return JSON.stringify({
    systemInstruction: {
      parts: [{ text: systemPrompt }]
    },
    contents: [{
      role: 'user',
      parts: [{ text: userPrompt }]
    }],
    generationConfig: {
      temperature: 0.7,
      maxOutputTokens: 8192,
      responseMimeType: 'application/json'
    }
  });
})() }}'''

nodes.append({
  "parameters": {
    "method": "POST",
    "url": "=https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-pro-preview:generateContent",
    "authentication": "predefinedCredentialType",
    "nodeCredentialType": "googlePalmApi",
    "sendBody": True,
    "specifyBody": "json",
    "jsonBody": gemini_prompt,
    "options": {
      "response": {
        "response": {}
      }
    }
  },
  "id": "a097b0d9-4b55-4238-a86a-1c9fe3c2d562",
  "name": "AI Generate Quiz Questions",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "position": [1500, 0],
  "credentials": {
    "googlePalmApi": {
      "id": "deiN1WmQ733K0N25",
      "name": "Google Gemini(PaLM) Api account"
    }
  }
})

# 8. Parse AI Quiz Response
nodes.append({
  "parameters": {
    "jsCode": """const item = $input.first();
const candidates = item.json.candidates || [];
const aiText = candidates[0]?.content?.parts?.[0]?.text || '';
const finishReason = candidates[0]?.finishReason || 'UNKNOWN';

const fileName = $('Extract Text Content').first().json.fileName;
const quizTitle = $('Extract Text Content').first().json.quizTitle;
const description = $('Extract Text Content').first().json.description;

if (!aiText) {
  throw new Error(`Gemini không trả về nội dung cho file ${fileName}. Finish reason: ${finishReason}`);
}

let parsedData;
try {
  let cleanResponse = aiText.replace(/^```json\\s*/m, '').replace(/```\\s*$/m, '').trim();
  parsedData = JSON.parse(cleanResponse);
} catch (e) {
  throw new Error(`Không thể parse Gemini response cho file ${fileName}: ${e.message}`);
}

let questions = [];
if (Array.isArray(parsedData)) {
  questions = parsedData;
} else if (parsedData.questions && Array.isArray(parsedData.questions)) {
  questions = parsedData.questions;
} else if (parsedData.quiz && Array.isArray(parsedData.quiz)) {
  questions = parsedData.quiz; 
} else {
  for (const key in parsedData) {
    if (Array.isArray(parsedData[key])) {
      questions = parsedData[key];
      break;
    }
  }
}

if (questions.length === 0) {
  throw new Error(`Gemini trả về JSON nhưng không tìm thấy danh sách câu hỏi.`);
}

return [{
  json: {
    fileName,
    quizTitle,
    description,
    questions,
    totalQuestions: questions.length,
    totalFiles: 1
  }
}];"""
  },
  "id": "4da48e68-609f-4c85-8137-ac35466a10bd",
  "name": "Parse AI Quiz Response",
  "type": "n8n-nodes-base.code",
  "typeVersion": 2,
  "position": [1750, 0]
})

# 9. Create Google Form
nodes.append({
  "parameters": {
    "method": "POST",
    "url": "https://forms.googleapis.com/v1/forms",
    "authentication": "predefinedCredentialType",
    "nodeCredentialType": "googleDriveOAuth2Api",
    "sendBody": True,
    "specifyBody": "json",
    "jsonBody": "={\\n  \\\"info\\\": {\\n    \\\"title\\\": \\\"{{ $json.quizTitle }}\\\"\\n  }\\n}\\n",
    "options": {
      "response": {
        "response": {
          "fullResponse": True
        }
      }
    }
  },
  "id": "defeb102-4135-458a-96da-499cdf27a801",
  "name": "Create Google Form",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "position": [2000, 0],
  "credentials": {
    "googleDriveOAuth2Api": {
      "id": "kIn77hC1D3e4d8C0",
      "name": "Google Drive account"
    }
  }
})

# 10. Extract Form ID
nodes.append({
  "parameters": {
    "jsCode": """const createResponse = $input.first().json.body || $input.first().json;
const quizData = $('Parse AI Quiz Response').first().json;

const formId = createResponse.formId;
const formUrl = createResponse.responderUri;

if (!formId) {
  throw new Error('Không thể tạo Google Form: ' + JSON.stringify(createResponse));
}

return [{
  json: {
    formId,
    formUrl,
    editUrl: `https://docs.google.com/forms/d/${formId}/edit`,
    quizTitle: quizData.quizTitle,
    questions: quizData.questions,
    totalQuestions: quizData.totalQuestions,
    totalFiles: quizData.totalFiles,
    description: quizData.description
  }
}];"""
  },
  "id": "9c87fb12-b154-4ab8-9928-d18d326c4e2a",
  "name": "Extract Form ID",
  "type": "n8n-nodes-base.code",
  "typeVersion": 2,
  "position": [2250, 0]
})

# 11. Add Quiz Questions to Form
add_questions_body = '''={{ (() => {
  const formId = $json.formId;
  const questions = $json.questions;
  
  const requests = [];
  
  if ($json.description) {
    requests.push({
      "updateFormInfo": {
        "info": {
          "description": $json.description
        },
        "updateMask": "description"
      }
    });
  }
  
  requests.push({
    "updateSettings": {
      "settings": {
        "quizSettings": {
          "isQuiz": true
        }
      },
      "updateMask": "quizSettings.isQuiz"
    }
  });
  
  questions.forEach((q, index) => {
    const options = Object.entries(q.options || {}).map(([key, value]) => ({
      "value": `${key}. ${value}`
    }));
    
    const correctKey = q.correctAnswer;
    const correctOptionValue = `${correctKey}. ${(q.options || {})[correctKey]}`;
    
    requests.push({
      "createItem": {
        "item": {
          "title": q.question,
          "description": q.explanation ? `💡 Giải thích: ${q.explanation}` : '',
          "questionItem": {
            "question": {
              "required": true,
              "grading": {
                "pointValue": 1,
                "correctAnswers": {
                  "answers": [{ "value": correctOptionValue }]
                },
                "whenRight": { "text": "✅ Chính xác!" },
                "whenWrong": { "text": `❌ Đáp án đúng là: ${correctOptionValue}` }
              },
              "choiceQuestion": {
                "type": "RADIO",
                "options": options,
                "shuffle": false
              }
            }
          }
        },
        "location": { "index": index }
      }
    });
  });
  
  return JSON.stringify({ requests });
})() }}'''

nodes.append({
  "parameters": {
    "method": "POST",
    "url": "=https://forms.googleapis.com/v1/forms/{{ $json.formId }}:batchUpdate",
    "authentication": "predefinedCredentialType",
    "nodeCredentialType": "googleDriveOAuth2Api",
    "sendBody": True,
    "specifyBody": "json",
    "jsonBody": add_questions_body,
    "options": {
      "response": {
        "response": {
          "fullResponse": True
        }
      }
    }
  },
  "id": "7aa47221-d920-474a-a4ba-6c6e183a4558",
  "name": "Add Quiz Questions to Form",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "position": [2500, 0],
  "credentials": {
    "googleDriveOAuth2Api": {
      "id": "kIn77hC1D3e4d8C0",
      "name": "Google Drive account"
    }
  }
})

# 12. Build Success Response
nodes.append({
  "parameters": {
    "jsCode": """const formData = $('Extract Form ID').first().json;
console.log(`✅ Đã tạo thành công bộ quiz với ${formData.totalQuestions} câu hỏi`);
return [{ json: { success: true, formId: formData.formId, formTitle: formData.quizTitle, formUrl: formData.formUrl, editUrl: formData.editUrl } }];"""
  },
  "id": "cf2fac80-5d99-418d-9a48-5bc4a5379cb7",
  "name": "Build Success Response",
  "type": "n8n-nodes-base.code",
  "typeVersion": 2,
  "position": [2750, 0]
})

connections = {
  "Google Drive Trigger": {
    "main": [
      [{"node": "Filter Markdown Files", "type": "main", "index": 0}]
    ]
  },
  "Filter Markdown Files": {
    "main": [
      [{"node": "Search Existing Form API", "type": "main", "index": 0}]
    ]
  },
  "Search Existing Form API": {
    "main": [
      [{"node": "Check If Form Exists", "type": "main", "index": 0}]
    ]
  },
  "Check If Form Exists": {
    "main": [
      [{"node": "Download Markdown File Content", "type": "main", "index": 0}]
    ]
  },
  "Download Markdown File Content": {
    "main": [
      [{"node": "Extract Text Content", "type": "main", "index": 0}]
    ]
  },
  "Extract Text Content": {
    "main": [
      [{"node": "AI Generate Quiz Questions", "type": "main", "index": 0}]
    ]
  },
  "AI Generate Quiz Questions": {
    "main": [
      [{"node": "Parse AI Quiz Response", "type": "main", "index": 0}]
    ]
  },
  "Parse AI Quiz Response": {
    "main": [
      [{"node": "Create Google Form", "type": "main", "index": 0}]
    ]
  },
  "Create Google Form": {
    "main": [
      [{"node": "Extract Form ID", "type": "main", "index": 0}]
    ]
  },
  "Extract Form ID": {
    "main": [
      [{"node": "Add Quiz Questions to Form", "type": "main", "index": 0}]
    ]
  },
  "Add Quiz Questions to Form": {
    "main": [
      [{"node": "Build Success Response", "type": "main", "index": 0}]
    ]
  }
}

data['nodes'] = nodes
data['connections'] = connections
data['name'] = "Quiz Generator Workflow V2"

with open('workflows/quiz_generator_workflow.json', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

