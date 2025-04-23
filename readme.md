
![logo](https://github.com/user-attachments/assets/02fce1d3-e020-4d89-b4bc-952056958bf4)

# Meep Research: Kind of Deep Research Tool but with _some_ control over sources.
> **Quick Start - Option 2:** For an automated setup (recommended), use our installation script:
> ```bash
> # Download the setup.sh script
> curl -O https://raw.githubusercontent.com/yourusername/meep-research/main/setup.sh
> # Make it executable
> chmod +x setup.sh
> # Run the script
> ./setup.sh
> ```
> The script will:
> - Check for Python 3.11+
> - Create a virtual environment
> - Install all required dependencies
> - Set up Chromium browser for automation
> - Create and launch the application
> 
> **Note on Security:** In general, you should be cautious about running scripts from the internet. You can inspect the code in these files to verify they're safe - they're open source and use standard libraries for browser automation and API access.

## Overview

Meep Research combines AI capabilities with browser automation to conductresearch across specified sources. Unlike generic AI assistants that choose their own data sources, this tool gives you complete control over your research inputs. Like this:

## Controlling Research Sources

### Using Search Engines Effectively

You can direct the tool to use specific search engines by providing their search URLs with your query parameters:

#### Google Search

```
https://www.google.com/search?q=artificial+intelligence+healthcare+diagnostics+site%3A.edu
```

#### Google Scholar

```
https://scholar.google.com/scholar?q=artificial+intelligence+medical+imaging+diagnostics
```

#### PubMed

```
https://pubmed.ncbi.nlm.nih.gov/?term=artificial+intelligence+diagnostics+accuracy
```


## Key Features

- **Source Control**: Explicitly define which websites, search engines, or databases to include in your research
- **Advanced Search Operators**: Leverage powerful search syntax across different platforms
- **AI-Driven Analysis**: Use Gemini models to understand content, extract insights, and synthesize findings
- **Automated Workflows**: Let the AI navigate through sources, following promising leads autonomously
- **Local Deployment**: Run everything on your own machine for privacy and customization

## Installation & Setup

### Prerequisites

- Python 3.8+ installed
- Chrome or Chromium browser installed
- A Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

### Installation Steps

1. Clone or download this repository to your local machine
2. Install the required dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Create a `.env` file in the root directory (optional) with your API key:
   ```
   GEMINI_API_KEY=your_api_key_here
   ```
4. Run the application:
   ```bash
   streamlit run app.py
   ```

## Usage Guide

### Basic Operation

1. Enter your Gemini API key (or it will use the one in your `.env` file)
2. Select the Gemini model you wish to use
3. Describe your research task in detail
4. Enter the URLs you want to investigate (one per line)
5. Click "Run Tasks" to begin the automated research

### Creating Effective Research Tasks

When describing your task, be specific about:

- What information you're seeking
- How deeply to analyze each source
- What format to present findings in
- Any specific questions to answer

**Example Task Description:**
```
Research the impact of artificial intelligence on healthcare diagnostics. Focus on peer-reviewed studies from the past 3 years. Identify key technological breakthroughs, accuracy rates compared to human diagnosticians, and ethical considerations. Compile findings into a structured report with sections for each of these areas. Include direct quotes from researchers when available.
```


### Using Search Engines Effectively

You can direct the tool to use specific search engines by providing their search URLs with your query parameters:

#### Google Search

```
https://www.google.com/search?q=artificial+intelligence+healthcare+diagnostics+site%3A.edu
```

#### Google Scholar

```
https://scholar.google.com/scholar?q=artificial+intelligence+medical+imaging+diagnostics
```

#### PubMed

```
https://pubmed.ncbi.nlm.nih.gov/?term=artificial+intelligence+diagnostics+accuracy
```

### Advanced Search Operators

Different search engines support various operators to refine your search. Here are some of the most useful:

#### Google Search Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `site:` | Limit results to specific domains | `site:edu artificial intelligence` |
| `filetype:` | Find specific file types | `filetype:pdf healthcare study` |
| `intitle:` | Search page titles | `intitle:machine learning medical` |
| `intext:` | Search body text | `intext:diagnostic accuracy AI` |
| `before:` / `after:` | Date range | `AI diagnostics after:2022` |
| `"exact phrase"` | Match exact phrase | `"precision medicine"` |
| `-term` | Exclude term | `AI healthcare -chatbot` |
| `OR` | Match either term | `diagnostics OR diagnosis` |
| `*` | Wildcard | `machine * learning healthcare` |

#### Google Scholar Specific

| Operator | Description | Example |
|----------|-------------|---------|
| `author:` | Search by author | `author:ng artificial intelligence` |
| `source:` | Search by publication | `source:nature machine learning` |

#### PubMed Specific

| Field | Description | Example Query |
|-------|-------------|--------------|
| `[Title]` | Search in title | `artificial intelligence[Title] AND diagnosis` |
| `[Author]` | Search by author | `Smith J[Author] AND AI` |
| `[Journal]` | Search specific journal | `AI[Title] AND NEJM[Journal]` |
| `[Publication Date]` | Date range | `AI diagnostics[Title] AND ("2020"[Publication Date] : "3000"[Publication Date])` |

### Custom Search Engines

You can also use custom search engines that focus on specific content types:

- **Semantic Scholar**: `https://www.semanticscholar.org/search?q=artificial+intelligence+diagnostics`
- **arXiv**: `https://arxiv.org/search/?query=artificial+intelligence+medical+imaging&searchtype=all`
- **ResearchGate**: `https://www.researchgate.net/search/publication?q=artificial+intelligence+diagnostics`

## Advanced Research Workflows
Using with Google Custom Search Engine
Enhance your research with Google Custom Search Engine (CSE) to focus only on trusted sources. To set one up: 
1) Visit programmablesearchengine.google.com,
2) Click "Create a search engine,"
3) Add the specific websites you want to search (e.g., academic journals, trusted news sources),
4) Customize settings like SafeSearch and region,
5) Get your search engine ID and create a search URL in this format: https://cse.google.com/cse?cx=YOUR_ENGINE_ID&q=YOUR_SEARCH_TERM. In Meep Research, simply paste this URL (replacing YOUR_SEARCH_TERM with your actual query) into the URLs field.
6) This allows your research to focus exclusively on high-quality sources you've pre-selected, eliminating questionable content and delivering more reliable insights.
## Privacy & Security

- All browsing happens on your local machine but data is still sent to google!
- Your API key is only shared with Google's Gemini API
- Browser sessions can be recorded locally (in the "recordings" folder) but are not shared


## Support & Resources

For more information on effective research techniques:

See search whisperer by Henk van Ess.

## License

steal everyhing
