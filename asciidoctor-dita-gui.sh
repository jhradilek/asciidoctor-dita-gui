#!/bin/bash

# A simple GUI for conversion from AsciiDoc to DITA
# Copyright (C) 2024 Jaromir Hradilek

# MIT License
#
# Permission  is hereby granted,  free of charge,  to any person  obtaining
# a copy of  this software  and associated documentation files  (the "Soft-
# ware"),  to deal in the Software  without restriction,  including without
# limitation the rights to use,  copy, modify, merge,  publish, distribute,
# sublicense, and/or sell copies of the Software,  and to permit persons to
# whom the Software is furnished to do so,  subject to the following condi-
# tions:
#
# The above copyright notice  and this permission notice  shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS",  WITHOUT WARRANTY OF ANY KIND,  EXPRESS
# OR IMPLIED,  INCLUDING BUT NOT LIMITED TO  THE WARRANTIES OF MERCHANTABI-
# LITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT
# SHALL THE AUTHORS OR COPYRIGHT HOLDERS  BE LIABLE FOR ANY CLAIM,  DAMAGES
# OR OTHER LIABILITY,  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM,  OUT OF OR IN CONNECTION WITH  THE SOFTWARE  OR  THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# General information about the script:
declare -r SCRIPT_NAME=${0##*/}
declare -r SCRIPT_VERSION='0.0.1'


# Print a message to standard error output and terminate the script with a
# specific exit status.
#
# Usage: exit_with_error MESSAGE [EXIT_STATUS]
function exit_with_error {
  local -r message=${1:-'An unexpected error has occurred'}
  local -r exit_status=${2:-1}

  # Print the supplied message to standard error output:
  echo -e "$SCRIPT_NAME: $message" >&2

  # Terminate the script with the selected exit status:
  exit $exit_status
}

# Convert the supplied AsciiDoc file to the selected DITA content type.
#
# Usage: convert_to_dita INPUT_FILE OUTPUT_FILE ATTRIBUTE_LIST SETTINGS
function convert_to_dita {
  local -r input_file="$1"
  local -r output_file="$2"
  local -r attributes=($3)
  local -r settings=$4

  # Compose the output type option:
  local content_type=$(echo "$settings" | sed '1q;d' | sed -e 's/Task (generated)/task-gen/;s/.*/\L&/')

  # Compose the UI macro option:
  local ui_macros=$(echo "$settings" | sed '2q;d' | grep -q 'Enabled' && echo '-a experimental' || echo '')

  # Compose the attribute definitions:
  local options=''
  for (( i=0; i<"${#attributes[@]}"; i++ )); do
    local value=$(echo "$settings" | sed "$(($i+3))q;d")
    [[ -z "$value" ]] && continue
    options+="-a ${attributes[$i]}=$value "
  done

  # Convert the file:
  asciidoctor -r dita-topic -b dita-topic -o - $ui_macros $options "$input_file" | dita-convert -t "$content_type" -o "$output_file" - 2>&1
}

# Open a dialog to display standard error output of the conversion:
#
# Usage: display_error_output ERROR_OUTPUT
function display_error_output {
  echo "$1" | sed -e 's/.*\(WARNING:.*\|ERROR:.*\)/\1/' | zenity --text-info --title='Warnings and errors' 2>/dev/null
}

# Parse the supplied AsciiDoc file and extract attributes from it.
#
# Usage: get_attribute_list FILE_NAME
function get_attribute_list {
  grep -hoP '\{\w[\w-]+\}' "$1" | tr -d '{}' | grep -ve '^nbsp$' | sort -uf
}

# Open a dialog to customize conversion settings.
#
# Usage: get_conversion_settings
function get_conversion_settings {
  if [[ -z "$1" ]]; then
    zenity --forms --title='Conversion Settings' --text='Customize the conversion settings and define attribute values' --separator=$'\n' --add-combo='Target DITA type' --combo-values='Concept|Reference|Task|Task (generated)|Topic' --add-combo='UI macros' --combo-values='Enabled|Disabled' 2>/dev/null
  else
    zenity --forms --title='Conversion Settings' --text='Customize the conversion settings and define attribute values' --separator=$'\n' --add-combo='Target DITA type' --combo-values='Concept|Reference|Task|Task (generated)|Topic' --add-combo='UI macros' --combo-values='Enabled|Disabled' `echo "$1" | sed -e 's/^/--add-entry=/'` 2>/dev/null
  fi
}

# Open a dialog window to select the input file.
#
# Usage: get_input_file
function get_input_file {
  zenity --file-selection --title='Select an AsciiDoc file' --file-filter='AsciiDoc Files | *.adoc' 2>/dev/null
}

# Open a dialog window to select the output file.
#
# Usage: get_output_file INPUT_FILE
function get_output_file {
  zenity --file-selection --title='Select the output destination' --save --file-filter='DITA Files | *.dita' --filename="${1%.adoc}.dita" 2>/dev/null
}


# Process command-line options:
while getopts ':hv' OPTION; do
  case "$OPTION" in
    h)
      # Print usage information and terminate the script:
      echo "Usage: $SCRIPT_NAME [FILE]"
      echo "       $SCRIPT_NAME [-hv]"
      echo
      echo '  -h           display this help and exit'
      echo '  -v           display version information and exit'
      exit 0
      ;;
    v)
      # Print the script version and terminate the script:
      echo "$SCRIPT_NAME $SCRIPT_VERSION"
      exit 0
      ;;
    *)
      # Report an invalid option and terminate the script:
      exit_with_error "Invalid option -- '$OPTARG'" 22
      ;;
  esac
done

# Shift positional parameters:
shift $(($OPTIND - 1))

# Verify the number of command-line arguments:
[[ "$#" -le 1 ]] || exit_with_error "Invalid number of arguments -- $#" 22

# Verify that all executables are available:
for executable in asciidoctor dita-convert gem; do
  if ! type "$executable" &>/dev/null; then
    exit_with_error "Missing executable -- '$executable'" 1
  fi
done

# Verify that required ruby gems are installed:
for ruby_gem in asciidoctor-dita-topic; do
  if ! gem list --silent -i "$ruby_gem"; then
    exit_with_error "Missing Ruby gem -- '$ruby_gem'" 1
  fi
done

# Get the path to the source file:
if [[ "$#" -eq 1 ]]; then
  input_file="$1"
else
  input_file=$(get_input_file)
  [[ "$?" -eq 0 ]] || exit_with_error "Aborted" 1
fi

# Verify that the supplied file exists and is readable:
[[ -e "$input_file" ]] || exit_with_error "$input_file: No such file or directory" 2
[[ -r "$input_file" ]] || exit_with_error "$input_file: Permission denied" 13
[[ -f "$input_file" ]] || exit_with_error "$input_file: Not a file" 21

# Get a list of attributes used in the source file:
attributes=$(get_attribute_list "$input_file")
[[ "$?" -eq 0 ]] || exit_with_error "Aborted" 1

# Get conversion settings, including the attribute values:
settings=$(get_conversion_settings "$attributes")
[[ "$?" -eq 0 ]] || exit_with_error "Aborted" 1

# Get the path to the output file:
output_file=$(get_output_file "$input_file")
[[ "$?" -eq 0 ]] || exit_with_error "Aborted" 1

# Run the conversion:
error_output=$(convert_to_dita "$input_file" "$output_file" "$attributes" "$settings")

# Terminate the script here if no warnings and error were detected:
[[ -z "$error_output" ]] && exit 0

# Display error output:
display_error_output "$error_output"

# Terminate the script:
exit 0

# Manual page:
:<<-=cut

=head1 NAME

asciidoctor-dita-gui - a simple GUI for conversion from AsciiDoc to DITA

=head1 SYNOPSIS

B<asciidoctor-dita-gui> [I<file>]

B<asciidoctor-dita-gui> B<-hv>

=head1 DESCRIPTION

The B<asciidoctor-dita-gui> extracts attribute names from the supplied
AsciiDoc file, allows you to define their values along with other
conversion parameters, and then converts the file to either DITA topic,
concept, reference, or task.

If no I<file> is supplied on the command line, B<asciidoctor-dita-gui>
opens a file dialog first to allow you to select a file to convert.

=head1 OPTIONS

=over

=item B<-h>

Displays usage information and terminates the script.

=item B<-V>

Displays the script version and terminates the script.

=back

=head1 SEE ALSO

B<asciidoctor>(1)

=head1 BUGS

To report a bug or submit a patch, please visit
L<https://github.com/jhradilek/asciidoctor-dita-gui/issues>.

=head1 COPYRIGHT

Copyright (C) 2024 Jaromir Hradilek E<lt>jhradilek@gmail.comE<gt>

This program is free software, released under the terms of the MIT license. It is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
