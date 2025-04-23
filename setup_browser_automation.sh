#!/bin/bash

echo "Setting up Browser Automation with Gemini..."

# 1. Check Python version (3.11+)
check_python() {
    echo "Checking Python version..."
    if command -v python3.11 &>/dev/null; then
        PYTHON_CMD="python3.11"
    elif command -v python3.12 &>/dev/null; then
        PYTHON_CMD="python3.12"
    elif command -v python3 &>/dev/null; then
        PYTHON_CMD="python3"
        PY_VERSION=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2)
        MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
        MINOR=$(echo "$PY_VERSION" | cut -d. -f2)
        if [[ "$MAJOR" -eq 3 && "$MINOR" -ge 11 ]]; then
            :
        else
            echo "Error: Python 3.11+ required. Found Python $PY_VERSION"
            exit 1
        fi
    else
        echo "Error: Python 3 not found. Please install Python 3.11+."
        exit 1
    fi
    echo "Using $PYTHON_CMD - $($PYTHON_CMD --version)"
}

check_python

# 2. Create & activate virtual environment
echo "Creating Python virtual environment..."
$PYTHON_CMD -m venv venv

echo "Activating virtual environment..."
source venv/bin/activate

# 3. Upgrade pip & install core Python packages
echo "Upgrading pip and installing core packages..."
$PYTHON_CMD -m pip install --upgrade pip
$PYTHON_CMD -m pip install \
    streamlit \
    google-generativeai \
    langchain-google-genai \
    pydantic \
    python-dotenv \
    browser-use \
    playwright \
    nest_asyncio \
|| { echo "Failed to install core Python packages."; exit 1; }

# 4. Install Chromium for Playwright
echo "Installing Playwright browser binaries..."
$PYTHON_CMD -m playwright install chromium || { echo "Failed to install Chromium via Playwright."; exit 1; }

# 5. Verify browser-use installation
echo "Verifying browser-use installation..."
$PYTHON_CMD - << 'PYCODE'
import sys
try:
    import browser_use
    print("browser_use import successful")
except Exception as e:
    print(f"Error: browser_use import failed: {e}", file=sys.stderr)
    sys.exit(1)
PYCODE

# 6. Create the Streamlit app file with updated code
echo "Creating the Streamlit app..."
cat > browser_automation.py << 'EOL'
import os
import asyncio
import streamlit as st
import traceback
from dotenv import load_dotenv
import logging
from pathlib import Path
import base64
import signal
import sys

# Try to import nest_asyncio, but handle it gracefully if not available
try:
    import nest_asyncio
    nest_asyncio.apply()
except ImportError:
    st.warning("nest_asyncio package not found. Some async operations may not work properly.")
    pass

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("browser_agent")

# Load environment and key
load_dotenv()

# Imports
try:
    import google.generativeai as genai
    from langchain_google_genai import ChatGoogleGenerativeAI
    from browser_use import Agent, Browser, BrowserContextConfig, BrowserConfig
    from browser_use.browser.context import BrowserContextConfig as ContextConfig
    from browser_use.browser.browser import BrowserContext
    from pydantic import SecretStr
except ImportError as e:
    st.error(f"Import error: {e}")
    st.stop()

# Global variables for resource management
browser_instances = []
context_instances = []

# Handle graceful shutdown
def handle_shutdown():
    """Clean up resources on shutdown"""
    for context in context_instances:
        try:
            asyncio.run(context.close())
        except:
            pass
    
    for browser in browser_instances:
        try:
            asyncio.run(browser.close())
        except:
            pass

# Setup browser context
async def setup_browser(headless: bool = True):
    try:
        browser = Browser(config=BrowserConfig(headless=headless))
        browser_instances.append(browser)
        
        context = await browser.new_context(
            config=ContextConfig(
                wait_for_network_idle_page_load_time=5.0,
                highlight_elements=True,
                save_recording_path="./recordings",
            )
        )
        context_instances.append(context)
        return browser, context
    except Exception as e:
        logger.error(f"Error setting up browser: {str(e)}")
        raise

# Single-URL run wrapper
def run_for_url(api_key, url, query, model, timeout):
    # Create a new event loop for each URL processing
    try:
        new_loop = asyncio.new_event_loop()
        asyncio.set_event_loop(new_loop)
    except RuntimeError:
        # If event loop is already set, use it
        new_loop = asyncio.get_event_loop()
    
    async def _run():
        browser = None
        context = None
        try:
            # Configure the API
            genai.configure(api_key=api_key)
            
            # Setup browser
            browser, context = await setup_browser(headless=True)
            
            # Setup initial actions
            initial_actions = [{"open_tab": {"url": url}}]
            
            # Initialize the LLM
            llm = ChatGoogleGenerativeAI(
                model=model,
                google_api_key=SecretStr(api_key),
                temperature=0.1,
                request_timeout=timeout,
                max_retries=2,
            )
            
            # Create and run the agent
            agent = Agent(
                task=query,
                llm=llm,
                browser_context=context,
                use_vision=True,
                generate_gif=True,
                initial_actions=initial_actions,
            )
            
            # Run the agent with timeout
            result = await asyncio.wait_for(agent.run(), timeout=timeout)
            return result.final_result() if result else None
        
        except asyncio.TimeoutError:
            return "Operation timed out. The task took too long to complete."
        except Exception as e:
            logger.error(f"Error during browser automation: {str(e)}")
            return f"Error: {str(e)}"
        finally:
            # Clean up resources
            if context:
                try:
                    await context.close()
                    if context in context_instances:
                        context_instances.remove(context)
                except:
                    pass
            
            if browser:
                try:
                    await browser.close()
                    if browser in browser_instances:
                        browser_instances.remove(browser)
                except:
                    pass
    
    try:
        # Run the async function in the new loop
        result = new_loop.run_until_complete(_run())
        if not new_loop.is_closed():
            new_loop.close()
        return result
    except Exception as e:
        logger.error(f"Error in event loop: {str(e)}")
        if not new_loop.is_closed():
            try:
                new_loop.close()
            except:
                pass
        return f"Event loop error: {str(e)}"

# Function to load and encode logo as base64
def get_base64_image(image_path):
    try:
        with open(image_path, "rb") as f:
            data = f.read()
        return base64.b64encode(data).decode()
    except Exception as e:
        logger.error(f"Error loading image: {str(e)}")
        return None

# Main Streamlit app
def main():
    # Register signal handlers for graceful shutdown
    try:
        signal.signal(signal.SIGINT, lambda sig, frame: (handle_shutdown(), sys.exit(0)))
        signal.signal(signal.SIGTERM, lambda sig, frame: (handle_shutdown(), sys.exit(0)))
    except:
        # Signal handlers may not work in all environments
        pass
    
    st.set_page_config(layout="wide")
    
    # App header with logo banner
    logo_path = "logo.png"
    
    # Check if logo file exists
    if Path(logo_path).exists():
        # Center the logo using HTML + base64 encoding
        encoded_logo = get_base64_image(logo_path)
        if encoded_logo:
            st.markdown(
                f"""
                <div style='text-align: center;'>
                    <img src='data:image/png;base64,{encoded_logo}' style='width: 600px;' />
                </div>
                """,
                unsafe_allow_html=True
            )
        else:
            st.title("Meep Research: Browser Automation with Gemini")
    else:
        # If logo doesn't exist, just use title
        st.title("Meep Research: Browser Automation with Gemini")
        
    st.markdown("<p style='font-style: italic; color: #666; text-align: center;'>Automate browser tasks with AI</p>", 
                unsafe_allow_html=True)
    st.markdown("---")
    
    # Create a cleaner single-panel layout with tabs
    tab1, tab2 = st.tabs(["🚀 Run Tasks", "ℹ️ About"])
    
    with tab1:
        # Main column layout
        col1, col2 = st.columns([3, 1])
        
        with col1:
            # Task input
            st.subheader("Task Configuration")
            query = st.text_area("Task to run", height=100, 
                                placeholder="Describe what you want the browser to do...")
            
            # URL input - one per line only
            urls_input = st.text_area(
                "URLs to visit (one per line)",
                height=80,
                placeholder="https://example.com\nhttps://another.com"
            )
        
        with col2:
            # API key and settings
            st.subheader("Settings")
            
            # Check if API key is already in environment
            default_api_key = os.environ.get("GEMINI_API_KEY", "")
            api_key = st.text_input("Gemini API Key", 
                                   value=default_api_key,
                                   type="password")
            
            # Model selection dropdown
            model_options = {
                "gemini-1.5-flash": "Gemini 1.5 Flash",
                "gemini-1.5-pro": "Gemini 1.5 Pro",
                "gemini-2.0-flash": "Gemini 2.0 Flash",
                "gemini-2.0-flash-exp": "Gemini 2.0 Flash (Experimental)",
                "gemini-2.5-flash": "Gemini 2.5 Flash",
                "gemini-2.5-pro": "Gemini 2.5 Pro"
            }
            selected_model = st.selectbox(
                "Select Gemini Model",
                options=list(model_options.keys()),
                format_func=lambda x: model_options[x],
                index=2  # Default to gemini-2.0-flash
            )
            
            # Option to save API key to environment
            if st.checkbox("Remember API Key (saves to .env file)", value=False):
                if api_key and api_key != default_api_key:
                    # Save to .env file - create or update
                    env_path = Path(".env")
                    
                    if env_path.exists():
                        # Read existing content
                        env_content = env_path.read_text()
                        if "GEMINI_API_KEY" in env_content:
                            # Update existing key
                            lines = env_content.splitlines()
                            updated_lines = []
                            for line in lines:
                                if line.startswith("GEMINI_API_KEY="):
                                    updated_lines.append(f"GEMINI_API_KEY={api_key}")
                                else:
                                    updated_lines.append(line)
                            env_path.write_text("\n".join(updated_lines))
                        else:
                            # Append new key
                            with env_path.open("a") as f:
                                f.write(f"\nGEMINI_API_KEY={api_key}")
                    else:
                        # Create new .env file
                        env_path.write_text(f"GEMINI_API_KEY={api_key}")
                    
                    st.success("API key saved to .env file")
                    os.environ["GEMINI_API_KEY"] = api_key
            
            timeout = st.slider("Timeout per URL (seconds)", 30, 900, 300)
        
        # Run button - centered and more prominent
        run_col1, run_col2, run_col3 = st.columns([1, 2, 1])
        with run_col2:
            run_button = st.button("🚀 Run Tasks", use_container_width=True, type="primary")
        
        # Results section
        if run_button:
            if not api_key or not urls_input or not query:
                st.error("❌ API key, at least one URL, and task description are required.")
                return
            
            # Test API key validity
            try:
                genai.configure(api_key=api_key)
                models = genai.list_models()  # This will fail if API key is invalid
                
                # Check if selected model is available
                model_names = [model.name for model in models]
                model_found = False
                for model_name in model_names:
                    if selected_model in model_name:
                        model_found = True
                        break
                
                if not model_found:
                    st.warning(f"⚠️ Selected model '{selected_model}' not found in available models. This may cause errors.")
                
            except Exception as e:
                st.error(f"❌ API key error: {str(e)}")
                return
            
            # Process URLs - one URL per line format only
            urls = [u.strip() for u in urls_input.splitlines() if u.strip()]
            
            if not urls:
                st.error("❌ No valid URLs found. Please provide at least one URL.")
                return
                
            # Display progress
            progress_container = st.container()
            with progress_container:
                progress_bar = st.progress(0)
                status_text = st.empty()
            
            # Process each URL
            results = {}
            for i, url in enumerate(urls):
                status_text.info(f"🔄 Processing URL {i+1}/{len(urls)}: {url}")
                progress_value = (i) / len(urls)
                progress_bar.progress(progress_value)
                
                try:
                    res = run_for_url(api_key, url, query, selected_model, timeout)
                    results[url] = res
                except Exception as e:
                    error_msg = f"Error processing {url}: {str(e)}"
                    st.error(error_msg)
                    results[url] = error_msg
                
            # Update progress to complete
            progress_bar.progress(1.0)
            status_text.success(f"🎉 All {len(urls)} tasks completed!")
            
            # Display results
            st.subheader("Results")
            for url, res in results.items():
                with st.expander(f"Results for: {url}", expanded=True):
                    if res:
                        st.write(res)
                    else:
                        st.warning("No result returned or task failed")
    
    with tab2:
        st.subheader("About Browser Automation with Gemini")
        st.markdown("""
        This application uses Google's Gemini models through the browser-use library to automate web browsing tasks.
        
        ### Features:
        - Process multiple URLs in a batch
        - Choose from various Gemini models
        - Generate detailed reports of automated browsing
        - Record browser automation sessions
        - Save your API key securely (optional)
        
        ### Supported Models:
        - **Gemini 1.5 Flash**: Fast, efficient model for straightforward tasks
        - **Gemini 1.5 Pro**: More powerful model with advanced reasoning
        - **Gemini 2.0 Flash**: Improved model with better performance
        - **Gemini 2.0 Flash (Experimental)**: Cutting-edge experimental version
        - **Gemini 2.5 Flash**: Latest flash model with thinking capabilities
        - **Gemini 2.5 Pro**: Most advanced model with superior reasoning
        
        ### How to Use:
        1. Enter your Gemini API key
        2. Select the model you want to use
        3. Enter a detailed task description
        4. List the URLs you want to process (one per line)
        5. Click "Run Tasks" to begin automation
        
        ### API Key Storage:
        If you choose to remember your API key, it will be saved to a local .env file.
        This is convenient but make sure to keep this file secure as it contains your API credentials.
        """)

if __name__ == "__main__":
    # Ensure recordings directory exists
    os.makedirs("recordings", exist_ok=True)
    
    try:
        main()
    finally:
        # Clean up resources when app exits
        handle_shutdown()
EOL

# 7. Create recordings directory
mkdir -p recordings

# 8. Create launcher script
echo "Creating launcher script..."
cat > run_app.sh << 'EOL'
#!/bin/bash
source venv/bin/activate
echo "Making sure nest_asyncio is installed..."
pip install nest_asyncio
echo "Starting Streamlit app..."
streamlit run browser_automation.py
EOL
chmod +x run_app.sh

# Final step: trigger the Streamlit app
echo "Setup complete! Starting the Streamlit app now..."
./run_app.sh