# CatPrinter App Agents Documentation

This document outlines the key AI agents and components used in the CatPrinter iOS application.

## Overview

CatPrinter is an iOS app that leverages AI for image generation, style transfer, inpainting, and OCR (Optical Character Recognition). The app uses Apple's Core ML and Stable Diffusion models to provide creative image editing capabilities.

## AI Agents/Components

### 1. ModelManager
**Purpose**: Central AI model management and image generation engine.

**Key Features**:
- Loads and manages Stable Diffusion pipeline
- Handles text-to-image generation
- Performs style transfer (image-to-image)
- Executes inpainting operations
- Manages model downloading and caching

**Technical Details**:
- Uses Core ML for on-device inference
- Supports multiple generation modes
- Implements progress tracking and cancellation
- Optimizes for iOS hardware (CPU + Neural Engine)

### 2. OCRViewModel
**Purpose**: Optical Character Recognition for text extraction from images.

**Key Features**:
- Extracts text from uploaded images
- Supports multiple languages
- Provides confidence scores
- Integrates with image processing pipeline

**Technical Details**:
- Uses Vision framework for text recognition
- Processes images asynchronously
- Returns structured text data

### 3. PrinterManager
**Purpose**: Handles printing operations and device communication.

**Key Features**:
- Manages Bluetooth/WiFi printer connections
- Formats images for printing
- Handles print job queuing
- Provides printer status monitoring

**Technical Details**:
- Uses Core Bluetooth for device communication
- Supports various printer protocols
- Implements error handling and retry logic

### 4. Face Detection Agent (Vision-based)
**Purpose**: Automatic face detection for image processing features.

**Key Features**:
- Detects faces in images using Apple's Vision framework
- Generates masks for face preservation during style transfer
- Supports multiple face detection in single images

**Technical Details**:
- Uses VNDetectFaceRectanglesRequest
- Converts Vision coordinates to UIKit coordinates
- Generates binary masks for inpainting operations

## Integration Flow

1. **Image Input**: User selects or captures an image
2. **Processing**: OCRViewModel extracts text if needed
3. **AI Generation**: ModelManager applies selected transformations
4. **Face Preservation**: Face detection creates masks for protected regions
5. **Output**: Processed image ready for printing via PrinterManager

## Model Requirements

- Stable Diffusion models stored in Documents/compiled directory
- Vision framework (built-in iOS)
- Core ML models for optimal performance

## Performance Considerations

- Models run on-device for privacy and speed
- Background processing to avoid UI blocking
- Memory optimization for iOS constraints
- Progressive loading and caching strategies

## Future Enhancements

- Additional AI models for specialized effects
- Improved face detection with landmarks
- Multi-language OCR expansion
- Advanced printing features

## Views

This section documents the key SwiftUI views in the CatPrinter application, their purposes, and main functionalities.

### 1. ContentView
**Purpose**: Main navigation and app entry point.

**Key Features**:
- Tab-based navigation between different app sections
- Manages overall app state and routing
- Displays navigation headers with accent color
- Handles model download status

**Technical Details**:
- Uses TabView for navigation
- Integrates with ModelManager for AI readiness
- Supports dark/light mode

### 2. CreateView
**Purpose**: Text-to-image generation interface.

**Key Features**:
- Prompt input for AI image generation
- Settings for steps, guidance, seed
- Image preview with zoom/pan modal
- Send to print functionality

**Technical Details**:
- Integrates with ModelManager.generate()
- Uses PhotosPicker for image selection
- Supports modal image zooming

### 3. StyleTransferView
**Purpose**: Image-to-image style transfer with face preservation.

**Key Features**:
- Style template selection (Sketch, Anime, Oil Paint, etc.)
- Editable prompts and negative prompts
- Face preservation toggle with auto-masking
- Settings for strength, steps, guidance, seed
- Image preview with zoom/pan modal

**Technical Details**:
- Uses Vision framework for face detection
- Routes through ModelManager.generateInpaint() when preserving faces
- Supports modal image zooming

### 4. InpaintingView
**Purpose**: Interactive image inpainting with drawing mask.

**Key Features**:
- Image selection and mask drawing
- Prompt and negative prompt inputs
- Settings for steps, guidance, seed
- Image preview with zoom/pan modal
- Send to print functionality

**Technical Details**:
- Uses PencilKit for mask drawing
- Integrates with ModelManager.generateInpaint()
- Supports modal image zooming

### 5. PrintView
**Purpose**: Print preview and job management.

**Key Features**:
- Image preview with zoom/pan modal
- Print settings (contrast, brightness, energy)
- Printer selection and connection
- OCR text extraction
- Print job queuing

**Technical Details**:
- Integrates with PrinterManager and OCRViewModel
- Uses PhotosPicker for image input
- Supports modal image zooming

### 6. OCRView
**Purpose**: Optical character recognition interface.

**Key Features**:
- Image upload and text extraction
- Language selection
- Confidence score display
- Extracted text editing

**Technical Details**:
- Uses OCRViewModel for text recognition
- Supports multiple languages via Vision framework

### 7. SettingsView
**Purpose**: App configuration and preferences.

**Key Features**:
- Model download management
- App theme settings
- Printer configuration
- General app settings

**Technical Details**:
- Manages ModelManager download state
- Persists user preferences

### 8. TemplatesView
**Purpose**: Template selection for printing.

**Key Features**:
- Pre-designed print templates
- Template customization
- Image placement and editing

**Technical Details**:
- Supports various template layouts
- Integrates with print functionality

### 9. ConnectionView
**Purpose**: Printer connection and management.

**Key Features**:
- Bluetooth/WiFi printer discovery
- Connection status monitoring
- Printer configuration

**Technical Details**:
- Uses PrinterManager for device communication
- Supports multiple printer protocols

### 10. DocumentScannerView
**Purpose**: Document scanning interface.

**Key Features**:
- Camera-based document capture
- Auto-cropping and perspective correction
- Scanned document preview

**Technical Details**:
- Uses Vision framework for document detection
- Integrates with camera APIs

### 11. BannerView
**Purpose**: Promotional or informational banners.

**Key Features**:
- Dynamic banner content
- Call-to-action buttons
- Dismissible notifications

**Technical Details**:
- Reusable banner component
- Supports rich text and images

### 12. ZoomableImageView & ZoomImageModal
**Purpose**: Interactive image viewing with zoom and pan.

**Key Features**:
- Pinch-to-zoom gestures
- Pan and double-tap controls
- Full-screen modal presentation

**Technical Details**:
- Custom UIViewRepresentable for zoom functionality
- Used across multiple views for image preview