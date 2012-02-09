
Name: chroot-tool
Group: Applications/System
Version: 0.1
Release: 0%{?dist}
Summary: A tool for creating and manipulating chroots

License: Apache 2.0

Source0: chroot-tool
Source1: yum.conf
Source2: chroot-tool.cfg

Requires: yum
Requires: rpm

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot

%description
A small, simple tool for creating and manipulating chroots

%prep
%setup -q -c -T

cp %{SOURCE0} .
cp %{SOURCE1} .
cp %{SOURCE2} .

%install
rm -rf $RPM_BUILD_ROOT

mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/%{name}
mkdir -p $RPM_BUILD_ROOT%{_sbindir}

install -m 0700 %{name} $RPM_BUILD_ROOT%{_sbindir}/%{name}
install -m 0644 tool.cfg $RPM_BUILD_ROOT%{_sysconfdir}/%{name}/tool.cfg
install -m 0644 yum.conf $RPM_BUILD_ROOT%{_sysconfdir}/%{name}/yum.conf

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{_sbindir}/%{name}
%config(noreplace) %{_sysconfdir}/%{name}/tool.cfg
%config(noreplace) %{_sysconfdir}/%{name}/yum.conf

%changelog

